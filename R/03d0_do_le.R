# targets::tar_workspace(data_le)

do_le <- function(
    data_combine_exposure_response,
    outfile
){
  
  # deaths and population by age group (aggregate sex)
  demographic_data <- data_combine_exposure_response[
    , .(deaths = sum(value), population = sum(pop))
    , by = .(country_name, province, age, sex, year)]
  
  # start age of age group for input to iomlifetR
  demographic_data[age == "<5 years", age := "0-5"]
  demographic_data[, age := as.integer(gsub("[^0-9]*([0-9]+).+", "\\1", age))]
  # demographic_data
  
  # calculate life expectancy from birth
  dat_le <- iomlifetR::burden_le(
    demog_data = demographic_data,
    min_age_at_risk = 30,
    pm_concentration = data_combine_exposure_response[, delta],
    RR = rr,
    unit = 10
  )
  
  return(dat_le)
}
