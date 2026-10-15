#' do_counterfactual_exposure
#'
#' Set the counterfactual exposure scenario, calculate delta
#'
#' @param data_baseline_exposure Target name - data_baseline_exposure (mean exposure level at jurisdictional level in data.table)
#' @param counterfactual_type Selected counterfactual type (e.g. absolute value ('abs'), minimum of exposures ('min'), or supply own data source)
#' @param counterfactual_value Counterfactual value if using an absolute value
#'
#' @returns data.table with exposure_baseline, counterfactual (exposure) and delta (difference)
do_counterfactual_exposure <- function(data_baseline_exposure, 
                                        scenario){
  if(scenario$counterfactual_type != "abs") message("Counterfactual type not 'abs', ignoring counterfactual_value...")
  
  dat_exposure <- data_baseline_exposure
  
  # Set counterfactual with given parameters ####
  
  ## if using minimum exposure value in data ####
  if(scenario$counterfactual_type == "min"){ 
    counterfactual_value <- dat_exposure[, min(exposure_baseline, na.rm = T)]
    dat_exposure[, counterfactual := counterfactual_value]
    
  ## if supplying absolute value ####
  } else if (scenario$counterfactual_type == "abs") {
    stopifnot("Missing a counterfactual absolute value for 'abs' counterfactual type" = !is.na(scenario$counterfactual_value))
    
    dat_exposure[, counterfactual := as.numeric(scenario$counterfactual_value)]
    # set counterfactual to equal baseline if baseline is lower than given threshold
    # i.e. exposure should not increase from baseline to counterfactual
    dat_exposure[counterfactual > exposure_baseline, counterfactual := exposure_baseline]
  }
   
  # label counterfactual scenario
  dat_exposure[, counterfactual_scenario := scenario$counterfactual_label]
  # calculate delta ####
  dat_exposure[, delta := (exposure_baseline - counterfactual)]
  
  return(dat_exposure)
}
