#' do_combine_exposure_response
#'
#' Combine baseline exposure, counterfactual exposure, population and mortality data into single data.table
#'
#' @param data_tidy_mortality Target name of cleaned mortality data
#' @param data_tidy_mortality_pop Target name of cleaned population data
#' @param data_construct_counterfactual Target name of counterfactual exposure
#' @param file_mapping File path to csv with mapping of jurisdictional names as provided in different data sources (geographic boundaries, mortality, population) - for standardising naming and merging
#'
#' @returns data.table with geographical identifiers, year, exposure and counterfactual (and delta), then mortality and population by sex and age:
#'    - country_code
#'    - country_name
#'    - province
#'    - year
#'    - exposure_baseline (exposure level at baseline scenario)
#'    - counterfactual (exposure level of counterfactual scenario)
#'    - delta (difference between counterfactual and baseline)
#'    - measure (response measure label)
#'    - sex
#'    - age (age group)
#'    - cause (cause of death)
#'    - number (mortality (death) count)
#'    - rate (mortality rate)
#'    - pop (population count)

do_combine_exposure_response <- function(
    data_tidy_mortality,
    data_tidy_mortality_pop,
    data_calc_exposure_by_geography,
    data_construct_counterfactual,
    file_mapping){
  
  ## read mapping of GADM and IHME location names
  dt_map <- fread(file_mapping)
  
  # Merge ####
  # Keep GADM names for output, discard IHME names
  # IHME - location
  # GADM - country_name, province
  
  # merge on mortality and population
  dt_combined_mort_pop <- data_tidy_mortality[data_tidy_mortality_pop, on = .NATURAL]
  
  # Combine Counterfactual (also containing baseline exposure) with mapping
  dt_exposure_response <- data_construct_counterfactual[dt_map, on = .(country_name, province), location := i.location]
  # attach on mortality/pop data
  dt_exposure_response <- dt_exposure_response[dt_combined_mort_pop, on = .(location = province, year)]
  
  # drop IHME location name
  dt_exposure_response[, location := NULL]
  # subset to study years
  dt_exposure_response <- dt_exposure_response[year %in% yys_todo]
  
  return(dt_exposure_response)
}
