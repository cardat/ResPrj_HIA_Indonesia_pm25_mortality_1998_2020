# targets::tar_workspace(viz_map_inputs_facet)

viz_map_inputs_facet <- function(data_combine_exposure_response = data_combine_exposure_response,
                           file_tidy_geography = file_tidy_geography,
                           yy = 2015:2020,
                           outdir = outdirs$figs_tabs,
                           nrow_facet = floor(sqrt(length(yy))),
                           asp_facet = 6/4) {
  
  # Read in data ####
  v <- sf::st_read(tar_read(file_tidy_geography), quiet = T)
  v <- sf::st_simplify(v, preserveTopology = T, dTolerance = 1000)
  dat <- data_combine_exposure_response
  # dat_exp_resp <- tar_read(data_combine_exposure_response)
  # dat_an <- tar_read(data_attributable_number)
  
  # dat <- cbind(dat_exp_resp, dat_an)
  
  # Plot population ####
  dat_pop <- dat[, .(pop = sum(pop)), by = .(country_name, province, year)]
  setorder(dat_pop, "year", "province")
  
  v_pop <- merge(v, dat_pop[year %in% yy])
  
  tm_pop <- tm_shape(v_pop) +
    tm_polygons(col = "pop",
                title = "Population",
                palette = "Blues") +
    tm_facets(by = "year", nrow = nrow_facet) + tm_layout(asp = asp_facet) +
    tm_scale_bar()

  # tm_pop_single <- tm_shape(v_pop[v_pop$year == yy, ]) +
  #   tm_polygons(col = "pop",
  #               title = "Population",
  #               palette = "Blues") +
  #   tm_graticules(col = "grey80") +
  #   tm_scale_bar()
  
  # tm_pop
  # tm_pop_single
  tmap_save(tm_pop, file.path(outdir, "map_population_facet.png"))
  # tmap_save(tm_pop_single, file.path(outdir, sprintf("map_population_%04i.png", yy)))
  
  
  # Plot mortality ####
  dat_mort <- dat[, .(mort = sum(count)), by = .(country_name, province, year)]
  setorder(dat_mort, "year", "province")
  
  v_mort <- merge(v, dat_mort[year %in% yy])
  
  tm_mort <- tm_shape(v_mort) +
    tm_polygons(col = "mort", title = "Mortality (per 100,000)") +
    tm_facets(by = "year", nrow = nrow_facet) + tm_layout(asp = asp_facet) +
    tm_scale_bar()
  
  # tm_mort_single <- tm_shape(v_mort[v_mort$year == yy, ]) +
  #   tm_polygons(col = "mort", title = "Mortality (per 100,000)") +
  #   tm_graticules(col = "grey80") +
  #   tm_scale_bar()
  
  # tm_mort
  # tm_mort_single
  tmap_save(tm_mort, file.path(outdir, "map_mortality_facet.png"))
  # tmap_save(tm_mort_single, file.path(outdir, sprintf("map_mortality_%04i.png", yy)))
  
  # Plot exposure ####
  dat_exposure <- unique(dat[, .(country_name, province, year, exposure_value)])
  setorder(dat_exposure, "year", "province")
  
  v_exposure <- merge(v, dat_exposure[year %in% yy])

  tm_exposure <- tm_shape(v_exposure) +
    tm_polygons(col = "exposure_value", title = "PM2.5 exposure",
                palette = "Oranges") +
    tm_facets(by = "year", nrow = nrow_facet) + tm_layout(asp = asp_facet) +
    tm_scale_bar()
  # tm_exposure_single <- tm_shape(v_exposure[v_exposure$year == yy, ]) +
  #   tm_polygons(col = "exposure_value",
  #               title = "PM2.5 exposure",
  #               palette = "Oranges") +
  #   tm_graticules(col = "grey80") +
  #   tm_scale_bar()
  
  
  # tm_exposure
  # tm_exposure_single
  tmap_save(tm_exposure, file.path(outdir, "map_exposure_facet.png"))
  # tmap_save(tm_exposure_single, file.path(outdir, sprintf("map_exposure_%04i.png", yy)))
  
  
  
  # tm_basemap("OpenStreetMap") + tm_shape(v_exposure[v_exposure$year == single_yy, ]) +
  #   tm_polygons(col = "exposure", title = "PM~2.5~ exposure") +
  #   tm_scale_bar()
  
  return(c(
    file.path(outdir, sprintf("map_population_facet.png")),
    file.path(outdir, sprintf("map_mortality_facet.png")),
    file.path(outdir, sprintf("map_exposure_facet.png"))
  ))
}