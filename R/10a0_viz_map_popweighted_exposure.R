# targets::tar_workspace(fig_map_exposure_response)

viz_map_exposure_response <- function(data_combined_exposure_response = data_combined_exposure_response,
                           file_tidy_geography = file_tidy_geography,
                           yy = 2015,
                           outdir) {
  # Read in data ####
  v <- sf::st_read(file_tidy_geography, quiet = T)
  v <- sf::st_simplify(v, preserveTopology = T, dTolerance = 1000)
  dat <- data_combined_exposure_response[counterfactual_scenario == "WHO AQG level"][year %in% yy]
  
  # Plot population ####
  dat_pop <- dat[, .(pop = sum(pop)), by = .(province, year)]
  setorder(dat_pop, "year", "province")
  
  v_pop <- merge(v, dat_pop[year == yy])
  
  tm_pop_single <- tm_shape(v_pop[v_pop$year == yy, ]) +
    tm_polygons(fill = "pop",
                fill.legend = tm_legend(title = "Population"),
                fill.scale = tm_scale(values = "brewer.blues")) |>
    standard_map_layout(credit_text = yy)
  
  tm_pop_single
  tmap_save(tm_pop_single, file.path(outdir, sprintf("map_population_%04i.png", yy)))
  
  
  # Plot mortality ####
  dat_mort <- dat[, .(mort = sum(number)), by = .(province, year)]
  setorder(dat_mort, "year", "province")
  
  v_mort <- merge(v, dat_mort[year == yy])
  
  tm_mort_single <- tm_shape(v_mort[v_mort$year == yy, ]) +
    tm_polygons(fill = "mort", 
                fill.legend = tm_legend(title = "Mortality count"),
                fill.scale = tm_scale(values = "brewer.reds")) |>
    standard_map_layout(credit_text = yy)
  
  tm_mort_single
  tmap_save(tm_mort_single, file.path(outdir, sprintf("map_mortality_%04i.png", yy)))
  
  # Plot exposure ####
  dat_exposure <- unique(dat[, .(province, year, exposure_baseline = exposure_baseline)])
  setorder(dat_exposure, "year", "province")
  
  v_exposure <- merge(v, dat_exposure[year == yy])

  tm_exposure_single <- tm_shape(v_exposure[v_exposure$year == yy, ]) +
      tm_polygons(
        fill = "exposure_baseline",
        fill.legend = tm_legend(title = "PM2.5 exposure"),
        fill.scale = tm_scale(values = "brewer.oranges")
      )|>
      standard_map_layout(credit_text = yy)
  
  tm_exposure_single
  tmap_save(tm_exposure_single, file.path(outdir, sprintf("map_exposure_%04i.png", yy)))
  
  return(c(
    file.path(outdir, sprintf("map_population_%04i.png", yy)),
    file.path(outdir, sprintf("map_mortality_%04i.png", yy)),
    file.path(outdir, sprintf("map_exposure_%04i.png", yy))
  ))
}
