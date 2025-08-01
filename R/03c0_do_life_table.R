# targets::tar_workspace(data_life_table)

do_life_table <- function(
    data_combine_exposure_response
){
  
  ages <- data_combine_exposure_response[, as.integer(gsub("([0-9]+).+", "\\1", age))]
  ages[is.na(ages)] <- 0
  
  hazard <- data_combine_exposure_response[, number / pop] 
  
  dat_life_table <- iomlifetR::life_table(
    hazard = hazard,
    start_age = ages
  )
  
  return(dat_life_table)
}
