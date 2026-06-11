#' do_calc_exposure_by_geography
#'
#' Extract exposure (mean) for each year across each jurisdictional polygon from rasters
#'
#' @param file_exposure File path to exposure rasters
#' @param file_tidy_geography File path to vector file of jurisdictional boundaries
#' @param file_population File path to rasters of population density. Optional, for population weighting
#' 
#' @returns data.table of country_code, country_name, province (jurisdiction), exposure_aggregation, year and exposure_baseline
do_calc_exposure_by_geography <- function(file_exposure,
                                          file_tidy_geography,
                                          file_population = NULL) {
  
  # Read and clean vector / raster data ####
  
  # Get study extent from geography (with buffer)
  v <- vect(file_tidy_geography)
  study_box <- terra::ext(v) + 0.3
  
  # Read raster, cropping to study area
  r_exposure <- lapply(file_exposure, rast, 
                       win = study_box, noflip = T)
  r_exposure <- do.call(c, r_exposure)
  
  # files do not have time component included, so determine the year from filename and attach to raster
  yys <- sapply(r_exposure, function(x){
    f <- basename(sources(x))
    as.integer(gsub(".+([0-9]{4})01-\\112.nc", "\\1", f))
  })

  time(r_exposure) <- yys
  names(r_exposure) <- yys

  ## Extraction of exposure level ####
  
  # Reproject vector layer
  v_reprojected <- terra::project(v, r_exposure)
  # double-check study boundaries are inside the raster
  stopifnot(all(terra::relate(v_reprojected, r_exposure, "within")))
  
  ### Without population provided ####
  if (is.null(file_population)){
    
    # extract (mean aggregate), weighted by fraction of cell covered
    e <- exactextractr::exact_extract(
      r_exposure,
      st_as_sf(v_reprojected),
      "mean",
      append_cols = c('country_name', 'country_code', 'province'),
      progress = F
    )
    
  } else {
    ### With population density - pop-weighted and unweighted ####  
  
    #### Read population raster ####
    r_population <- do.call(c, lapply(file_population, rast))
    time(r_population) <- as.integer(gsub(".+pd_([0-9]{4})_.+", "\\1", basename(file_population)))
    names(r_population) <- sprintf("pop_density_%i", time(r_population))
    
    # align population to exposure rasters with resample
    r_population_aligned <- resample(r_population, r_exposure)
    
    # common time period
    available_yys <- intersect(time(r_exposure), time(r_population_aligned))
    
    #### Extract pop-weighted and unweighted ####
    e <- exactextractr::exact_extract(
      r_exposure[[time(r_exposure) %in% available_yys]],
      st_as_sf(v_reprojected),
      c('mean', 'weighted_mean'),
      weights = r_population_aligned,
      default_weight = 0,
      coverage_area = TRUE,
      append_cols = c('country_name', 'country_code', 'province'),
      progress = F
    )
    setDT(e)
    
    ## This is a terra-based alternative to calculate population-weighted means ####
    #  but MUCH slower ####
    # dat_pop.terra <- extract(r_population_aligned, v, fun = "sum", weights = T, na.rm = T, ID = F)
    # dat_pop_exp.terra <- extract(r_exposure_aligned*r_population_aligned[[16]],
    #                          v,
    #                          fun = "sum",
    #                          weights = T,
    #                          na.rm = T,
    #                          ID = F)
    # dat.exp <- cbind(
    # data.table(country_name = v$country_name, province = v$province), 
    # dat_pop_exp.terra/dat_pop.terra)
    # dat.exposure <- melt(dat.exp, id.vars = "province",
    #                      variable.name = "year",
    #                      variable.factor = F,
    #                      value.name = "exposure_baseline")
    # dat.exposure[, year := as.integer(year)]
  }
  
  setDT(e)
  
  # melt to long format and tidy
  dat.exposure <- melt(e, 
                       id.vars = intersect(names(v), names(e)), 
                       variable.name = "year", 
                       variable.factor = F,
                       value.name = "exposure_baseline")
  
  dat.exposure[, exposure_aggregation := gsub("^(.+?)\\..+", "\\1", year)]
  dat.exposure[, year := as.integer(gsub(".+([0-9]{4})$", "\\1", year))]
  dat.exposure[exposure_aggregation == "weighted_mean", exposure_aggregation := "population-weighted mean"]
  
  setcolorder(dat.exposure, c("country_name", "country_code", "province", "exposure_aggregation", "year", "exposure_baseline"))
  return(dat.exposure)
}
