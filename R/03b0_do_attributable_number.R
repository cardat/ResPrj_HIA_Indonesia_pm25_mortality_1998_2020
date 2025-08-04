# targets::tar_workspace(data_attributable_number)

do_attributable_number <- function(
    data_combine_exposure_response
){
  # deaths and population by age group (aggregate sex)
  demographic_data <- data_combine_exposure_response[
    , .(deaths = sum(count), population = sum(pop))
    , by = .(country_name, province, age, sex, year, delta)]
  
  # start age of age group for input to iomlifetR
  demographic_data[age == "<5 years", age := "0-5"]
  demographic_data[, age := as.integer(gsub("[^0-9]*([0-9]+).+", "\\1", age))]
  # demographic_data
  
  dat_an <- iomlifetR::burden_an(
    demog_data = demographic_data, 
    min_age_at_risk = minimum_age_risk, 
    pm_concentration = demographic_data[, delta],
    RR = rr[1],
    unit = units_rr_per
  )
  
  return(dat_an)
}