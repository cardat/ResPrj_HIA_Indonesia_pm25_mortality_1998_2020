# targets::tar_workspace(data_calc_exposure_by_geography)

do_calc_exposure_by_geography <- function(file_exposure,
                                          file_tidy_geography,
                                          variable_name) {
  
  # Get study extent from geography (with buffer)
  v <- vect(file_tidy_geography)
  study_box <- terra::ext(v) + 0.3
  
  # Read in raster, cropped to study area
  r_exposure <- lapply(file_exposure, rast, 
                       win = study_box, noflip = T)
  r_exposure <- do.call(c, r_exposure)
  
  # attach years
  yys <- sapply(r_exposure, function(x){
    f <- basename(sources(x))
    as.integer(gsub(".+([0-9]{4})01-\\112.nc", "\\1", f))
  })

  time(r_exposure) <- yys
  names(r_exposure) <- yys

  # double-check
  stopifnot(all(terra::relate(v, r_exposure, "within")))

  ## do extraction, weighted by fraction of cell covered
  v_reprojected <- terra::project(v, r_exposure)
  e <- terra::extract(r_exposure, v_reprojected, weights = TRUE,
                      fun = mean, na.rm = TRUE,
                      ID = FALSE)
  
  dat.exposure <- cbind(values(v),
                        e)
  
  setDT(dat.exposure)
  dat.exposure <- melt(dat.exposure, id.vars = names(v), 
                       variable.name = "year", value.name = "value",
                       variable.factor = F)
  dat.exposure[, year := as.integer(year)]

  return(dat.exposure)
}
