#' do_mortality_burden
#'
#' Calculate mortality burden (as attributable number, change in life expectancy and years of life lost) with iomlifetR package
#'
#' @param data_combine_exposure_response Target name - data.table of combined exposure, counterfactual and response data by province, age, sex, etc.
#'
#' @returns 
do_mortality_burden <- function(
  data_combine_exposure_response = data_combine_exposure_response
){
  # Prepare data ####
  # life tables are calculated based on one set of age groups (i.e. age groups from 0 to ... for a single province/sex/cause/year...)
  # so split into groupings (each group containing a full set of ages)
  dat_groups <- split(data_combine_exposure_response, 
                      by = c("country_code", "country_name", "province", "measure", "cause", "sex", "year")
  )
  
  # Burden calculations for each group ####
  dat_burden_group <- lapply(dat_groups, function(x){
    # x <- dat_groups[[200]]
    
    # demographic data must be contain fields 'age' (with beginning age of age group), 'population' and 'deaths'.
    demog_x <- x[, .(age = age,
                     population = pop,
                     deaths = count,
                     delta = delta)]
    demog_x[, age := as.character(age)]
    demog_x[age == "<5 years", age := "0-5 years"]
    demog_x[, age := as.integer(gsub("([0-9]+).+", "\\1", age))]
    
    # check
    # age ordered sequentially?
    stopifnot(demog_x$age == sort(demog_x$age)) 
    # demog_x
    
    ## Calculate attributable number ####
    # set min_age_at_risk, RR, and unit in global params
    dat_an <- iomlifetR::burden_an(
      demog_data = demog_x, 
      min_age_at_risk = minimum_age_risk, 
      pm_concentration = demog_x[, delta],
      RR = rr[1], 
      unit = units_rr_per
    )
    
    
    ## Calculate change in life expectancy ####
    # - life tables for baseline and impacted
    # - and differences in life-expectancy, life-years lived and number of deaths
    dat_le <- iomlifetR::burden_le(
      demog_data = demog_x,
      min_age_at_risk = minimum_age_risk, 
      pm_concentration = demog_x[, delta],
      RR = rr[1], 
      unit = units_rr_per
    )
    
    ## Calculate years of life lost ####
    # (from attributable number and impacted life expectancy)
    dat_yll <- iomlifetR::burden_yll(attributable_number = dat_an,
                                     life_expectancy = dat_le$impacted[, "ex"])
    
    ## Combine neatly for output
    base_output <- x[, .(country_code, country_name, province, measure, sex, age, cause, year)]
    dat_burden_x <- cbind(base_output, data.table( 
                          attributable_deaths = dat_an,
                          years_of_life_lost = dat_yll,
                          diff_life_expectancy = dat_le$difference$ex_diff,
                          diff_life_years_lived = dat_le$difference$ly_diff,
                          diff_number_of_deaths = dat_le$difference$dx_diff
                          ))
    
    dat_lifet_baseline_x <- cbind(base_output, subset(dat_le$baseline, select = -age))
    dat_lifet_impacted_x <- cbind(base_output, subset(dat_le$impacted, select = -age))
    
    return(list(mortality_burden = dat_burden_x,
                baseline_life_table = dat_lifet_baseline_x,
                impacted_life_table = dat_lifet_impacted_x)
    )
  })
  
  # Combine and format for neat output ####
  dat_burden <- rbindlist(lapply(dat_burden_group, `[[`, "mortality_burden"))
  
  dat_life_tables <- list(baseline = rbindlist(lapply(dat_burden_group, `[[`, "baseline_life_table")),
                          impacted = rbindlist(lapply(dat_burden_group, `[[`, "impacted_life_table")))
  
  return(list(burden = dat_burden, life_tables = dat_life_tables))
}