viz_mortality_impact <- function(
  data_mortality_impact = data_mortality_impact,
  yy = qc_yy,
  outdir = figdir
){
  
  vals <- c("ly_current", "ly_extended", "deaths_current", "deaths_extended")
  
  # Subset and aggregate ages and provinces to national level, all agees
  dat <- data_mortality_impact[exposure_pop_year == yy][, 
                               lapply(.SD, sum), 
                               .SDcols = vals,
                               by = setdiff(names(data_mortality_impact), c(vals, "age", "province"))]
  
  # Melt to long format
  dat.v2 <- melt(dat, 
                 measure.vars = vals,
                 variable.name = "variable", 
                 value.name = "value")
  
  # cast the confidence intervals
  dat_aggregated <- dcast(dat.v2, formula = "... ~ RR", value.var = "value")
  setnames(dat_aggregated, names(dat_aggregated), gsub("HRAPIE", "value", names(dat_aggregated)))
  
  # set factor levels
  dat_aggregated[, counterfactual_scenario := factor(counterfactual_scenario,
                                                     levels = c("WHO Interim Target 3", 
                                                                "WHO Interim Target 4",
                                                                "WHO AQG level"))]
  dat_aggregated[, variable := factor(variable,
                                      levels = vals)]
  
  # Plot deaths avoided ####
  to_plt.deaths <- dat_aggregated[variable %in% c("deaths_current", "deaths_extended") & counterfactual_scenario == "WHO AQG level"]
  plt.deaths <- ggplot(to_plt.deaths,
         aes(x = year, y = value, col = variable)) + 
    geom_line(lty = "dashed") +
    geom_point() +
    facet_wrap(~counterfactual_scenario, ncol = 1) +
    labs(title = "Deaths avoided (no lag)",
         caption = "WHO AQG level = 5ug/m^3") +
    xlab("Year") + ylab("Number ('000)") +
    scale_y_continuous(labels = scales::number_format(scale = 0.001)) +
    geom_hline(yintercept = 0, col = "grey70") +
    scale_color_manual(values = c("black", "red"),
                       labels = c("Current cohort", "Extended population")
    )
  
  # Plot life years gained ####
  to_plt.ly <- dat_aggregated[variable %in% c("ly_current", "ly_extended") & counterfactual_scenario == "WHO AQG level"]
  plt.ly <- ggplot(to_plt.ly,
         aes(x = year, y = value, col = variable)) + 
    geom_line(lty = "dashed") +
    geom_point() +
    facet_wrap(~counterfactual_scenario, ncol = 1) +
    labs(title = "Life-years gained (no lag)",
         caption = "WHO AQG level = 5ug/m^3") +
    xlab("Year") + ylab("Number ('000 000)") +
    scale_y_continuous(labels = scales::number_format(scale = 1e-6)) +
    geom_hline(yintercept = 0, col = "grey70") +
    scale_color_manual(values = c("black", "red"),
                       labels = c("Current cohort", "Extended population")
    )
  
  # Output ####
  outfs <- file.path(outdir,
                     c(sprintf("deaths_avoided_%04i.png", yy),
                       sprintf("life_years_gained_%04i.png", yy)))
  
  ggsave(outfs[1],
         plt.deaths
  )
  ggsave(outfs[2],
         plt.ly
  )
  
  return(outfs)
  
 
}
