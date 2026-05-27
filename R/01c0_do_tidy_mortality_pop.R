#' do_tidy_mortality_pop
#' 
#' Clean raw population data.
#'
#' @param data_tidy_mortality 
#'
#' @returns data.table with population count by mortality measure, province, sex, age, cause and year
do_tidy_mortality_pop <- function(data_tidy_mortality){
  
  # Calculate from IHME estimates - may be replaced with census data if available
  dat <- data_tidy_mortality[, .(pop = number / (rate/100000)), by = .(measure, province, sex, age, cause, year)]
  
  return(dat)
}
