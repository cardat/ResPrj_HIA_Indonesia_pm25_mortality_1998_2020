do_mortality_impact <- function(
  data_combined_exposure_response = data_combined_exposure_response,
  data_tidy_population_age_sex = data_tidy_population_age_sex,
  relative_risk,
  reference_year
){
  setDT(data_combined_exposure_response)
  setDT(data_tidy_population_age_sex)
  
  data_combined_exposure_response <- data_combined_exposure_response[year == reference_year]
  
  ## aggregate across sex
  # Exposure-reponse
  data_combined_exposure_response.aggregated <- data_combined_exposure_response[, .(pop = sum(pop), number = sum(number)), 
                                                                                by = .(year, province, age_group, delta)]
  # 1yr group populations
  data_tidy_population_age_sex.aggregated <- data_tidy_population_age_sex[, .(pop_count = sum(pop_count)), by = .(province, year, age)]
  
  # tidy population data, ready to merge
  data_tidy_population_age_sex.aggregated
  
  
  
  ls_data <- split(data_combined_exposure_response.aggregated,
                   by = c("year", "province"))

  t1 <- Sys.time()
  impact <- lapply(ls_data, function(x){
    # demographic data must be contain fields 'age' (with beginning age of age group), 'population' and 'deaths'.
    stopifnot(nrow(unique(x[, .(year, province)])) == 1)
    
    demog_x <- data_tidy_population_age_sex.aggregated[
      province == unique(x$province) & year == unique(x$year),
      .(age, age_group_5yr = age %/% 5 * 5, population = pop_count)]
    
    
    deaths_interpolated <- merge(x[, .(age_group_5yr = age_group, deaths_5yr = number)],
                                 demog_x,
                                 by = "age_group_5yr")
    
    # Assume UNIFORMLY distributed deaths in age group
    deaths_interpolated[, deaths := deaths_5yr/.N, by = .(age_group_5yr)]
    setorder(deaths_interpolated, age)
    
    demog_x <- deaths_interpolated[, .(age, population, deaths = deaths)]
    setorder(demog_x, age)
    # check
    # age ordered sequentially?
    stopifnot(demog_x$age == sort(demog_x$age)) 
    
    
    # needs to be single year for lm.fit, fails with 5yr age groups
    no_lag <- iomlifetR::impact(
      demog_x[, .(age, population, deaths)],
      delta_pm = unique(x$delta),
      min_age_at_risk = minimum_age_risk,
      RR = relative_risk$RR,
      unit = relative_risk$per_unit_change
    )
    
    # cat(paste(unique(x$year), unique(x$province),"\n"))
    return(no_lag)
  })
  t2 <- Sys.time()
  cat(t2-t1)
  
  impact_collated <- lapply(impact, function(x) {
    x_collated <- lapply(seq_along(x), function(i) {
      dat <- as.data.table(x[[i]], keep.rownames = T)
      setnames(dat, "rn", "age")
      dat2 <- melt(
        dat,
        id.vars = "age",
        variable.name = "year",
        variable.factor = F,
        value.name = names(x)[i]
      )
      
      dat2[, names(.SD) := lapply(.SD, as.integer), .SDcols = is.character]
      return(dat2)
    })
    Reduce(merge, x_collated)
  })
  
  impact_collated <- rbindlist(impact_collated, idcol = "set")
  impact_collated[, `:=`(exposure_pop_year = as.integer(gsub("^([0-9]{4}).+", "\\1", set)),
                         province = gsub("^[0-9]{4}\\.", "", set),
                         set = NULL)]
  impact_collated[, `:=`(counterfactual_scenario = unique(data_combined_exposure_response$counterfactual_scenario),
                         RR = relative_risk$RR_label)]
  
  return(impact_collated)
}
