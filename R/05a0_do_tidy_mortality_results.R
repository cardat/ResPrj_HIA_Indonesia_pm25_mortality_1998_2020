do_tidy_mortality_results <- function(data_mortality_burden, 
                                           outdir = "data_derived"){
  
  tbl_scenario_rr <- rbindlist(lapply(data_mortality_burden, function(i) as.list(i[["scenario"]])))
  
  # combine tables, labelling with scenario and relative risk used
  combined_burden <- rbindlist(lapply(seq_along(data_mortality_burden), function(i) {
    # i <- 1
    cbind(tbl_scenario_rr[i,], data_mortality_burden[[i]]$burden)
  }))
  combined_burden[, names(.SD) := lapply(.SD, round, 2), .SDcols = is.double]
  
  
  combined_life_tables <- rbindlist(lapply(seq_along(data_mortality_burden), function(i){
    # i <- 1
    cbind(tbl_scenario_rr[i,], 
          rbindlist(data_mortality_burden[[i]]$life_tables, idcol = "life_table_type")
    )
  }))
  
  
  # Descriptive field names
  setnames(combined_burden,
           c("an", "yll", "ex_diff", "ly_diff", "dx_diff"),
           c("burden_attributable_number", 
             "burden_years_of_life_lost", 
             "difference_age_specific_life_expectancy",
             "difference_age_specific_life_year_lived_per_100000",
             "difference_age_specific_num_deaths_per_100000"
             ))
  
  setnames(combined_life_tables,
           c("hazard", "Ix", "Sx", "dx", "Lx", "ex"),
           c("age_specific_hazard", 
             "population_surviving_from_100000", 
             "survival_probability", 
             "num_deaths_per_100000", 
             "num_lyl_per_100000", 
             "life_expectancy"))
  
  # Save
  if(!dir.exists(outdir)) dir.create(outdir, recursive = T)
  
  outf_burden <- file.path(outdir, 
                           sprintf("mortality_burden_%s.csv", runDate))
  fwrite(combined_burden, outf_burden)
  
  outf_life_tables <- file.path(outdir, 
                                sprintf("mortality_lifetables_%s.csv", runDate))
  fwrite(combined_life_tables, outf_life_tables)
  
  return(c(
    outf_burden,
    outf_life_tables
  ))
}
