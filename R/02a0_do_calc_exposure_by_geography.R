#' do_calc_exposure_by_geography
#'
#' Extract exposure (mean) for each year across each jurisdictional polygon from rasters
#'
#' @param file_exposure File path to exposure rasters
#' @param file_tidy_geography File path to vector file of jurisdictional boundaries
#' 
#' @returns data.table of country_code, country_name, province (jurisdiction), year and exposure_baseline
do_calc_exposure_by_geography <- function(file_exposure,
                                          file_tidy_geography) {
  
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
  
  # extract (mean aggregate), weighted by fraction of cell covered
  e <- terra::extract(r_exposure, v_reprojected, weights = TRUE,
                      fun = mean, na.rm = TRUE,
                      ID = FALSE)
  
  # attach to vector fields (jurisdictional names)
  dat.exposure <- cbind(values(v),
                        e)
  setDT(dat.exposure)
  
  # melt to long format and tidy
  dat.exposure <- melt(dat.exposure, id.vars = names(v), 
                       variable.name = "year", 
                       variable.factor = F,
                       value.name = "exposure_baseline")
  dat.exposure[, year := as.integer(year)]

  return(dat.exposure)
}
