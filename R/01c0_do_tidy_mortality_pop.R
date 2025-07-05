# targets::tar_workspace(data_tidy_mortality_pop)

do_tidy_mortality_pop <- function(data_tidy_mortality){
  
  dat <- data_tidy_mortality[, .(pop = number / (rate/100000)), by = .(measure, location, sex, age, cause, year)]
  
  return(dat)
}
