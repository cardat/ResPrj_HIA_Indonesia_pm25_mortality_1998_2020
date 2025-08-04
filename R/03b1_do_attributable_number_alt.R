# targets::tar_workspace(data_attributable_number_alt)

do_attributable_number_alt <- function(
    hif,
    data_combine_exposure_response,
    minimum_age
){
  data_combine_exposure_response[grepl("^<5", age), start_age := 0L]
  data_combine_exposure_response[is.na(start_age), start_age := as.integer(gsub("([0-9]+).+", "\\1", age))]
  
  dat_attributable <- data_combine_exposure_response[, .(country_name, province, measure,
                                                         sex, start_age, age, cause, year, 
                                                         delta, count, rate, pop)]
  
  dat_attributable[start_age < minimum_age, attributable := 0]

  dat_attributable[is.na(attributable), c("attributable", "lci", "uci") := hif(delta) * pop * (rate/100000)]
  
  dat_attributable[, start_age := NULL]
  
  return(dat_attributable)
}