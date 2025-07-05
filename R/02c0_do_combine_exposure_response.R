#' Calculate pop-weighted exposure, aggregate and merge with study population data
#'
#' @param dt_study_pop_health A data table of the study population and expected impact by SA2, age group, year.
#' @param dt_env_counterfactual A data table of the environmental exposure (value), counterfactual scenario (cf) and calculated delta, by year and spatial unit
#' @param dt_exp_pop A data table of spatial unit population
#'
#' @return A data table of dt_study_pop_health with attached population-weighted exposures for baseline (x) and counterfactual (v1) scenarios, by year and SA2.
 
# tar_source("config.R")
# dt_study_pop_health <- tar_read(data_study_pop_health)
# dt_env_counterfactual <- tar_read(combined_exposures)
# dt_exp_pop <- tar_read(data_study_pop_health)
# gid <- GADM_gid <- c("ID_1", "NAME_1")
# mapping_f <- sprintf("mapping_files/%s_gid_map.csv", country_code)

do_combine_exposure_response <- function(
  dt_study_pop_health,
  dt_env_counterfactual,
  dt_exp_pop,
  gid,
  mapping_f = NULL){
  
  if(!is.null(mapping_f)){
    dt_map <- fread(mapping_f)
    dt_expo <- merge(dt_study_pop_health[, .(location_name, sex_name, age_5y_group, year, estimated_pop)], dt_map, 
                     by.x = "location_name", by.y = "ihme_name")
    dt_expo <- merge(dt_expo, dt_env_counterfactual,
                     by.x = c("gdam_name", "year"), 
                     by.y = c("NAME_1", "year"), allow.cartesian = T)
    dt_expo[, gdam_name := NULL]
  }
  
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
