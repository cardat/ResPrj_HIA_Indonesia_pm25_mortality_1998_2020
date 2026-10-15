generate_health_impact_function <- function(
    exposure_response_func = 1.062, # from HRAPIE project
    theoretical_minimum_risk = 0,
    unit_change = 10
){
  
  ## relative risk per ? unit change
  beta <- log(exposure_response_func)/unit_change
  # beta
  # e.g. if unit change is 10
  # exp(beta * x)
  # ## or alternately
  # exposure_response_func^(x/10)
  
  resp_func <- function(x){
    sapply(x, function(i){
      
    
    
    # return NA if don't have i
    if (is.nan(i) | is.na(i)) return(NA)
    
    # no attribution if below theoretical minimum risk
    if(i < theoretical_minimum_risk) return(rep(0))
    
    return( (exp(beta * i)-1) / exp(beta * i) )
    # Alternately 1 - 1/exp(beta * i)
    })
  }
    
  return(resp_func)
}
