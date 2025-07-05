# targets::tar_workspace(data_construct_counterfactual)

do_construct_counterfactual <- function(data_calc_exposure_by_geography, 
                                        counterfactual_type,
                                        counterfactual_value){
  
  dat_exposure <- data_calc_exposure_by_geography
  
  # Set counterfactual with given parameters ####
  
  ## if using minimum exposure value in data ####
  if(counterfactual_type == "min"){ 
    counterfactual_value <- dat_exposure[, min(value, na.rm = T)]
    dat_exposure[, counterfactual := counterfactual_value]
    
  ## if supplying absolute value ####
  } else if (counterfactual_type == "abs") {
    stopifnot("Missing a counterfactual absolute value for 'abs' counterfactual type" = !missing(counterfactual_value))
    
    dat_exposure[, counterfactual := counterfactual_value]
    # set counterfactual to equal baseline if baseline is lower than given threshold
    # i.e. exposure should not increase from baseline to counterfactual
    dat_exposure[counterfactual > value, counterfactual := value]
  }
   
  # calculate delta ####
  dat_exposure[, delta := (value - counterfactual)]
  
  return(dat_exposure)
}