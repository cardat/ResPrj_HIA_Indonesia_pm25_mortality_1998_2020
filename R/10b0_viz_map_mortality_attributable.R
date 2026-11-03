# targets::tar_workspace(fig_map_mortality_attributable)

viz_map_mortality_attributable <- function(data_attributable_number = data_attributable_number,
                                           file_tidy_geography = file_tidy_geography,
                                           yy = 2015,
                                           outdir) {
  # Read in data ####
  v <- sf::st_read(file_tidy_geography, quiet = T)
  v <- sf::st_simplify(v, preserveTopology = T, dTolerance = 1000)
  dat <- data_attributable_number[counterfactual_scenario == "WHO AQG level" &
                                    RR_selected == "HRAPIE"][year %in% yy]
  
  # Plot attributable number ####
  dat_an <- dat[, .(attributable_number = sum(attributable_number)), by = .(province, year, RR_selected, counterfactual_scenario)]
  setorder(dat_an, "year", "province")
  
  v_an <- merge(v, dat_an[year == yy])
  
  tm_an_single <- tm_shape(v_an) +
    tm_polygons(fill = "attributable_number", 
                fill.legend = tm_legend(title = "Attributable number of deaths (PM2.5)"),
                fill.scale = tm_scale(values = "brewer.reds")) |>
    standard_map_layout(credit_text = yy)
  
  tm_an_single
  tmap_save(tm_an_single, file.path(outdir, sprintf("map_attributable_number_%04i.png", yy)))
  
  
  return(
    file.path(outdir, sprintf("map_attributable_number_%04i.png", yy))
    )
}
