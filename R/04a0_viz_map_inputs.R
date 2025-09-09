# targets::tar_workspace(fig_map_inputs)

viz_map_inputs <- function(data_combine_exposure_response = data_combine_exposure_response,
                           file_tidy_geography = file_tidy_geography,
                           yy = 2020,
                           outdir = outdirs$figs_tabs) {
  # Read in data ####
  v <- sf::st_read(tar_read(file_tidy_geography), quiet = T)
  v <- sf::st_simplify(v, preserveTopology = T, dTolerance = 1000)
  dat <- data_combine_exposure_response
  
  # Plot population ####
  dat_pop <- dat[, .(pop = sum(pop)), by = .(country_name, province, year)]
  setorder(dat_pop, "year", "province")
  
  v_pop <- merge(v, dat_pop[year == yy])
  
  tm_pop_single <- tm_shape(v_pop[v_pop$year == yy, ]) +
    tm_polygons(fill = "pop",
                fill.legend = tm_legend(title = "Population"),
                fill.scale = tm_scale(values = "brewer.blues")) +
    tm_graticules(col = "grey80") +
    tm_scalebar()
  
  tm_pop_single
  tmap_save(tm_pop_single, file.path(outdir, sprintf("map_population_%04i.png", yy)))
  
  
  # Plot mortality ####
  dat_mort <- dat[, .(mort = sum(count)), by = .(country_name, province, year)]
  setorder(dat_mort, "year", "province")
  
  v_mort <- merge(v, dat_mort[year == yy])
  
  tm_mort_single <- tm_shape(v_mort[v_mort$year == yy, ]) +
    tm_polygons(fill = "mort", 
                fill.legend = tm_legend(title = "Mortality (per 100,000)"),
                fill.scale = tm_scale(values = "-brewer.rd_bu")) +
    tm_graticules(col = "grey80") +
    tm_scalebar()
  
  tm_mort_single
  tmap_save(tm_mort_single, file.path(outdir, sprintf("map_mortality_%04i.png", yy)))
  
  # Plot exposure ####
  dat_exposure <- unique(dat[, .(country_name, province, year, exposure_value = exposure_value)])
  setorder(dat_exposure, "year", "province")
  
  v_exposure <- merge(v, dat_exposure[year == yy])

  tm_exposure_single <- tm_shape(v_exposure[v_exposure$year == yy, ]) +
    tm_polygons(fill = "exposure_value", 
                fill.legend = tm_legend(title = "PM2.5 exposure"),
                fill.scale = tm_scale(values = "brewer.oranges")) +
    tm_graticules(col = "grey80") +
    tm_scalebar()
  
  
  tm_exposure_single
  tmap_save(tm_exposure_single, file.path(outdir, sprintf("map_exposure_%04i.png", yy)))
  
  return(c(
    file.path(outdir, sprintf("map_population_%04i.png", yy)),
    file.path(outdir, sprintf("map_mortality_%04i.png", yy)),
    file.path(outdir, sprintf("map_exposure_%04i.png", yy))
  ))
}
