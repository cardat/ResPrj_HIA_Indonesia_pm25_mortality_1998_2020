# targets::tar_workspace(fig_map_attributable_number_alt)

viz_map_attributable_number_alt <- function(data_attributable_number_alt = data_attributable_number_alt,
                                        file_tidy_geography = file_tidy_geography,
                                        yy = 2015:2020,
                                        outdir = outdirs$figs_tabs,
                                        nrow_facet = floor(sqrt(length(yy))),
                                        asp_facet = 6/4) {
  # Read in data ####
  v <- sf::st_read(tar_read(file_tidy_geography), quiet = T)
  v <- sf::st_simplify(v, preserveTopology = T, dTolerance = 1000)
  
  # aggregate
  dat_an <- data_attributable_number_alt[, .(attributable = sum(attributable)), by = .(country_name, province, measure, age, cause, year)]
  v_an <- merge(v, dat_an[year %in% yy])
  
  tm_an <- tm_shape(v_an) +
    tm_polygons(col = "attributable",
                title = "Attributable number",
                palette = "Reds") +
    tm_facets(by = "year", nrow = nrow_facet) + 
    tm_layout(asp = asp_facet) +
    tm_scale_bar()
  
  tmap_save(tm_an, file.path(outdir, sprintf("map_attributable_calculated_%04i_%04i.png", min(yy), max(yy))))
  
  return(c(
    file.path(outdir, sprintf("map_attributable_calculated_%04i_%04i.png", min(yy), max(yy)))
  ))
}