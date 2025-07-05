# targets::tar_workspace(data_life_tables)

do_life_tables <- function(
    data_combine_exposure_response,
    outfile
){
  
  ages <- data_combine_exposure_response[, as.integer(gsub("([0-9]+).+", "\\1", age))]
  ages[is.na(ages)] <- 0
  
  hazard = data_combine_exposure_response[, number / pop] 
  
  # not correct, fix
  dat_life_table <- iomlifetR::life_table(
    hazard = hazard,
    start_age = ages
  )
  
  if(!dir.exists(dirname(outfile))) dir.create(dirname(outfile))
  fwrite(dat_life_table, outfile)
  return(outfile)
}
