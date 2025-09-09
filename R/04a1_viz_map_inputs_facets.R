# targets::tar_workspace(fig_map_inputs_facet)

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
  
  # Plot population ####
  dat_pop <- dat[, .(pop = sum(pop)), by = .(country_name, province, year)]
  setorder(dat_pop, "year", "province")
  
  v_pop <- merge(v, dat_pop[year %in% yy])
  
  tm_pop <- tm_shape(v_pop) +
    tm_polygons(fill = "pop",
                fill.legend = tm_legend(title = "Population"),
                fill.scale = tm_scale(values = "brewer.blues")) +
    tm_facets(by = "year", nrow = nrow_facet) + 
    tm_layout(asp = asp_facet) +
    tm_scalebar()

  tmap_save(tm_pop, file.path(outdir, "map_population_facet.png"))

  # Plot mortality ####
  dat_mort <- dat[, .(mort = sum(count)), by = .(country_name, province, year)]
  setorder(dat_mort, "year", "province")
  
  v_mort <- merge(v, dat_mort[year %in% yy])
  
  tm_mort <- tm_shape(v_mort) +
    tm_polygons(fill = "mort", 
                fill.legend = tm_legend(title = "Mortality (per 100,000)"),
                fill.scale = tm_scale(values = "-brewer.rd_bu")) +
    tm_facets(by = "year", nrow = nrow_facet) + 
    tm_layout(asp = asp_facet) +
    tm_scalebar()
  
  tmap_save(tm_mort, file.path(outdir, "map_mortality_facet.png"))
  
  # Plot exposure ####
  dat_exposure <- unique(dat[, .(country_name, province, year, exposure_value)])
  setorder(dat_exposure, "year", "province")
  
  v_exposure <- merge(v, dat_exposure[year %in% yy])

  tm_exposure <- tm_shape(v_exposure) +
    tm_polygons(fill = "exposure_value", 
                fill.legend = tm_legend(title = "PM2.5 exposure"),
                fill.scale = tm_scale(values = "brewer.oranges")) +
    tm_facets(by = "year", nrow = nrow_facet) + tm_layout(asp = asp_facet) +
    tm_scalebar()
  
  tmap_save(tm_exposure, file.path(outdir, "map_exposure_facet.png"))
  
  return(c(
    file.path(outdir, sprintf("map_population_facet.png")),
    file.path(outdir, sprintf("map_mortality_facet.png")),
    file.path(outdir, sprintf("map_exposure_facet.png"))
  ))
}
