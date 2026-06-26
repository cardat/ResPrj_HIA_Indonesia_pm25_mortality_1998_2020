#' do_construct_counterfactual
#'
#' Set the counterfactual exposure scenario
#'
#' @param data_calc_exposure_by_geography Target name - data_calc_exposure_by_geography (mean exposure level at jurisdictional level in data.table)
#' @param counterfactual_type Selected counterfactual type (e.g. absolute value ('abs'), minimum of exposures ('min'), or supply own data source)
#' @param counterfactual_value Counterfactual value if using an absolute value
#'
#' @returns data.table with exposure_baseline, counterfactual (exposure) and delta (difference)
do_construct_counterfactual <- function(data_calc_exposure_by_geography, 
                                        cf_scenario){
  if(cf_scenario$scenario_type != "abs") message("Counterfactual type not 'abs', ignoring counterfactual_value...")
  
  dat_exposure <- data_calc_exposure_by_geography
  
  # Set counterfactual with given parameters ####
  
  ## if using minimum exposure value in data ####
  if(cf_scenario$scenario_type == "min"){ 
    counterfactual_value <- dat_exposure[, min(exposure_baseline, na.rm = T)]
    dat_exposure[, counterfactual := cf_scenario$scenario_value]
    
  ## if supplying absolute value ####
  } else if (cf_scenario$scenario_type == "abs") {
    stopifnot("Missing a counterfactual absolute value for 'abs' counterfactual type" = !is.na(cf_scenario$scenario_value))
    
    dat_exposure[, counterfactual := cf_scenario$scenario_value]
    # set counterfactual to equal baseline if baseline is lower than given threshold
    # i.e. exposure should not increase from baseline to counterfactual
    dat_exposure[counterfactual > exposure_baseline, counterfactual := exposure_baseline]
  }
   
  # label counterfactual scenario
  dat_exposure[, counterfactual_scenario := cf_scenario$scenario]
  # calculate delta ####
  dat_exposure[, delta := (exposure_baseline - counterfactual)]
  
  return(dat_exposure)
}
