# targets::tar_workspace(health_impact_function)

do_health_impact_function <- function(
  exposure_response_func = c(1.062, 1.040, 1.083), # from HRAPIE project, with lower and upper bounds
  theoretical_minimum_risk = 0
){
  
  # this is a relative risk per 10 unit change
  unit_change <- 10
  beta <- log(exposure_response_func)/unit_change
  beta
  # e.g. if unit change is 10
  # exp(beta * x)
  # ## or alternately
  # exposure_response_func^(x/10)
  
  resp_func <- function(x){
    
    response <- sapply(x, function(i) {
      # no attribution if below theoretical minimum risk
      if(i < theoretical_minimum_risk){
        return(c(0,0,0))
      } else {
        exp(beta * i) - 1
      }
    })
    
    # tidy to a 3-column table
    response <- t(response)
    response <- as.data.table(response)
    names(response) <- c("resp", "lci", "uci")
    return(response)
  }
  
  return(resp_func)
}