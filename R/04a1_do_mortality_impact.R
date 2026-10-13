do_mortality_impact <- function(
  data_combine_exposure_response = data_combine_popw_exposure_response,
  data_tidy_population_age_sex = data_tidy_population_age_sex
){
  setDT(data_combine_exposure_response)
  setDT(data_tidy_population_age_sex)
  
  ls_data <- split(data_combine_exposure_response[, .(year, province, sex, age, pop, number, delta)],
                   by = c("year", "province", "sex"))

  impact <- lapply(ls_data, function(x){
    # demographic data must be contain fields 'age' (with beginning age of age group), 'population' and 'deaths'.
    stopifnot(nrow(unique(x[, .(year, province, sex)])) == 1)
    
    demog_x <- data_tidy_population_age_sex[location == unique(x$province) & year == unique(x$year) & sex == unique(x$sex),
                                            .(age, population = pop_count)]
    demog_x[, age_group_5yr := sprintf("%i-%i years", (age %/% 5)*5,
                                       (age %/% 5)*5 + 4)]
    demog_x[age %between% c(0, 4), age_group_5yr := "<5 years"]
    demog_x[age == 95, age_group_5yr := "95+ years"]
    
    deaths_interpolated <- merge(x[, .(age_group_5yr = age, deaths_5yr = number)],
                                 demog_x,
                                 by = "age_group_5yr")
    
    # Assume UNIFORMLY distributed deaths in age group
    deaths_interpolated[, deaths := deaths_5yr/.N, by = .(age_group_5yr)]
    setorder(deaths_interpolated, age)
    
    ####### This is a spline version... ############
    # deaths_interpolated[, deaths_splined := spline(deaths_5yr,
    #                                                xout = age)$y]
    # splining_prep <- deaths_interpolated[, .(age = mean(age), deaths = deaths_5yr/.N), by = .(age_group_5yr, deaths_5yr)]
    # a <- spline(splining_prep$age,
    #             splining_prep$deaths,
    #             xout = 0:95)
    # 
    # deaths_interpolated[, deaths_splined := a$y]
    # plot(deaths_interpolated$age, deaths_interpolated$deaths_5yr)
    # points(deaths_interpolated$age, deaths_interpolated$deaths, col = "blue")
    # points(deaths_interpolated$age, deaths_interpolated$deaths_splined, col = "red")
    # 
    # deaths_interpolated[, .(sum(deaths_splined)), by = .(age_group_5yr, deaths_5yr)]
    
    demog_x <- deaths_interpolated[, .(age, population, deaths = deaths)]
    setorder(demog_x, age)
    # check
    # age ordered sequentially?
    stopifnot(demog_x$age == sort(demog_x$age)) 
    
    
    # needs to be single year for lm.fit, fails with 5yr age groups
    no_lag <- iomlifetR::impact(
      demog_x[, .(age, population, deaths)],
      min_age_at_risk = minimum_age_risk,
      RR = RRs_todo[1, value],
      unit = units_rr_per
    )
    
}
