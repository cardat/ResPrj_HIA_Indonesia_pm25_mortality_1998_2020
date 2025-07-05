do_health_impact_function <- function(
  case_definition = 'crd',
  exposure_response_func = c(1.06, 1.02, 1.08),
  theoretical_minimum_risk = 0
){
  fnc <- function(x) {x + 1}
  
  return(fnc)
}