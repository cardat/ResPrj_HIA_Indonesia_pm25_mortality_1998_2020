# targets::tar_workspace(data_attributable_number)

do_attributable_number <- function(
    hif,
    data_combine_exposure_response,
    minimum_age,
    outfile
){
  data_combine_exposure_response[grepl("^<5", age), start_age := 0L]
  data_combine_exposure_response[is.na(start_age), start_age := as.integer(gsub("([0-9]+).+", "\\1", age))]
  
  dat_attributable <- data_combine_exposure_response[start_age >= minimum_age, .(country_name, province, measure,
                                                                                 sex, age, cause, year, delta, number)]
  dat_attributable[, c("attributable", "lci", "uci") := hif(delta) * number]
  
  if(!dir.exists(dirname(outfile))) dir.create(dirname(outfile))
  fwrite(dat_attributable, outfile)
  return(outfile)
}