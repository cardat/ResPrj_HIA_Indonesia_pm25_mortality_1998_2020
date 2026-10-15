# targets::tar_workspace(data_attributable_number)

do_attributable_number <- function(
    data_combined_exposure_response,
    relative_risk
){
  # # deaths and population by age group (aggregate sex)
  # demographic_data <- data_combined_exposure_response[
  #   , .(deaths = sum(count), population = sum(pop))
  #   , by = .(country_name, province, age, sex, year, delta)]
  # 
  # # start age of age group for input to iomlifetR
  # demographic_data[age == "<5 years", age := "0-5"]
  # demographic_data[, age := as.integer(gsub("[^0-9]*([0-9]+).+", "\\1", age))]
  # # demographic_data
  
  calculate_attributable_number <- generate_health_impact_function(exposure_response_func = relative_risk$RR, 
                                                                   theoretical_minimum_risk = relative_risk$theoretical_minimum_risk,
                                                                   unit_change = relative_risk$per_unit_change
                                                                   )
  
  dat_an <- copy(data_combined_exposure_response)
  dat_an[, attributable_number := calculate_attributable_number(delta)*number]
  
  ##********************************************************#
  # REMOVE AND FIX
  dat_an[age_group < minimum_age_risk, attributable_number := 0]
  
  # tar_read(data_mortality_burden, branches = 1)[[1]]
  # tar_read(data_mortality_burden, branches = 1)[[2]][order(province, age, sex, year)]
  # dat_an[order(province, age, sex, year)]
  
  # b <- dcast(a[counterfactual_scenario == "WHO AQG level"], formula = ... ~ RR_selected, value.var = "attributable_number")
  # library(ggplot2)
  # ggplot(b[age %notin% c("<5 years", "5-9 years", "10-14 years", "15-19 years", "20-24 years", "25-29 years")], aes(x = year, y = HRAPIE, ymin = HRAPIE_CI_lower, ymax = HRAPIE_CI_upper,
  #               colour = age, lty = sex)) +
  #   facet_wrap(~province, scales = "free") +
    # geom_line()
  
  ##********************************************************#
  
  dat_an[, RR_selected := relative_risk$RR_label]
  
  return(dat_an)
}