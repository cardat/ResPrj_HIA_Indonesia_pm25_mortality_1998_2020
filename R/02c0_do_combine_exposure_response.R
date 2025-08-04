# targets::tar_workspace(data_combine_exposure_response)

do_combine_exposure_response <- function(
    data_tidy_mortality,
    data_tidy_mortality_pop,
    data_calc_exposure_by_geography, 
    data_construct_counterfactual,
    file_mapping){
  
  ## read mapping of GADM and IHME location names
  dt_map <- fread(file_mapping)
  
  # Merge ####
  # Use GADM names when merging IHME and GADM data together
  # IHME - location
  # GADM - country_name, province
  dt_combined <- dt_map[, .(location, country_name, province)]
  
  # add mortality and population
  dt_combined <- dt_combined[data_tidy_mortality, on = .(location)]
  dt_combined <- dt_combined[data_tidy_mortality_pop, on = .NATURAL]
  
  # add exposure and counterfactual
  dt_combined <- dt_combined[data_construct_counterfactual, on = .(country_name, province, year)]
  
  # drop IHME name
  dt_combined[, location := NULL]
  
  setnames(dt_combined, "number", "count")
  setnames(dt_combined, "value", "exposure_value")

  return(dt_combined)
}
