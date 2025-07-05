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
  
  dt_expo <- merge(dt_study_pop_health[, .(location_name, sex_name, age_5y_group, year, estimated_pop)], dt_map, 
                     by.x = "location_name", by.y = "ihme_name")
    dt_expo <- merge(dt_expo, dt_env_counterfactual,
                     by.x = c("gdam_name", "year"),
                     by.y = c("NAME_1", "year"), allow.cartesian = T)
    dt_expo[, gdam_name := NULL]

  #### population-weighted exposures ####
  dt_expo <- merge(dt_env_counterfactual, dt_exp_pop, by = gid)
  dt_expo_agg <- dt_expo[, .(
    x = sum(value * pop, na.rm = T) / sum(pop, na.rm = T),
    v1 = sum(delta * pop, na.rm = T) / sum(pop, na.rm = T),
    pop = sum(pop, na.rm = T)
    ),
    by = c(gid, "year", "variable")]
  # some x and v1 are NaN since 0 pop present
  
  #### merge with population response ####
  dt <- merge(dt_study_pop_health, 
              dt_expo_agg[, .(sa2_main16, year, variable, x, v1)],
              by = c("sa2_main16", "year"))
  
  return(dt)
}

# dt_study_pop_health <- tar_read(data_study_pop_health)
# dt_env_counterfactual <- tar_read(combined_exposures)
# dt_exp_pop <- tar_read(tidy_exp_pop)
