# targets::tar_workspace(fig_map_attributable_number)

viz_map_attributable_number <- function(data_combine_exposure_response = data_combine_exposure_response,
                                        data_attributable_number = data_attributable_number,
                                        file_tidy_geography = file_tidy_geography,
                                        yy = 2015:2020,
                                        outdir = outdirs$figs_tabs,
                                        nrow_facet = floor(sqrt(length(yy))),
                                        asp_facet = 6/4) {
  # Read in data ####
  v <- sf::st_read(tar_read(file_tidy_geography), quiet = T)
  v <- sf::st_simplify(v, preserveTopology = T, dTolerance = 1000)
  
  dat_an <- data_combine_exposure_response
  dat_an[, attributable := data_attributable_number]
  
  # aggregate
  dat_an <- dat_an[, .(attributable = sum(attributable)), by = .(country_name, province, measure, age, cause, year)]
  v_an <- merge(v, dat_an[year %in% yy])
  
  # plot
  tm_an <- tm_shape(v_an) +
    tm_polygons(fill = "attributable",
                fill.legend = tm_legend(title = "Attributable number"),
                fill.scale = tm_scale(values = "brewer.reds")) +
    tm_facets(by = "year", nrow = nrow_facet) + 
    tm_layout(asp = asp_facet) +
    tm_scalebar()
  
  # Save the plot
  if(!dir.exists(outdir)) dir.create(outdir, recursive = T)
  outfile <- file.path(outdir, sprintf("map_attributable_%04i_%04i.png", min(yy), max(yy)))
  
  tmap_save(tm_an, outfile)
  
  return(c(outfile))
}