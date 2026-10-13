#' do_tidy_population_age_sex
#'
#' Clean raw population by age and sex data. Output population count by province, sex, age and year
#'
#' @param  File path to raw population data
#'
#' @returns data.table of population data with fields province, sex, age, year, number (count)
do_tidy_population_age_sex <- function(file_population_age_sex){
  
  # Subset data to relevant columns and rows ####
  dat <- rbindlist(lapply(file_population_age_sex, fread))
  # years of this study
  dat <- dat[year %in% yys_todo]
  
  dat.all_ages <- dat[age_name == "All ages"]
  dat.1yr_grp <- dat[age_name != "All ages"]
  
  # Checks ####
  # Age groups add up to expected total (all ages)
  stopifnot(identical(
    dat.1yr_grp[, round(sum(val)), by = .(location_name, sex_name, year)][
      order(location_name, sex_name, year)],
    dat.all_ages[, .(V1 = round(val)), by = .(location_name, sex_name, year)][
      order(location_name, sex_name, year)]
  ))
  
  # all years, sex and age groups present
  # expected 46 per location-agegroup combo (number of study years * two sexes)
  stopifnot(
    table(dat.1yr_grp[, .(age_name, location_name)]) == length(yys_todo)*2
    )
  # expected 2208 per sex-location combo (number of age groups * number of study years)
  stopifnot(
    table(dat.1yr_grp[, .(sex_name, location_name)]) == 96*length(yys_todo)
  )
  # expected total rows if all sexes, locations, age groups and years present
  stopifnot(nrow(unique(dat.1yr_grp[, .(sex_name, location_name, age_name, year)])) == 
              2 * length(unique(dat.1yr_grp$location_name)) * length(unique(dat.1yr_grp$age_name)) * length(yys_todo))
  
  
  dat.v2 <- dat.1yr_grp[, .SD, .SDcols = grepl("_name$|year|val|upper|lower", names(dat.1yr_grp))]
  setnames(dat.v2, names(dat.v2), gsub("_name$", "", names(dat.v2)))
  
  setnames(dat.v2, "age", "source_age")
  # recode age to integer
  dat.v2[source_age == "<1 year", age := 0L]
  dat.v2[source_age == "12-23 months", age := 1L]
  dat.v2[source_age == "95+ years", age := 95L]
  dat.v2[is.na(age), age := as.integer(source_age)]
  
  #unique(dat.v2[, .(source_age, age)][order(age)])
  stopifnot(dat.v2[, sort(unique(age))] == 0:95)
  
  # Is population counts only, drop extraneous columns
  stopifnot(all(dat.v2$population_group == "All Population"))
  stopifnot(all(dat.v2$measure == "Population"))
  stopifnot(all(dat.v2$metric == "Number"))
  
  dat.v2[, `:=`(source_age = NULL,
                population_group = NULL,
                measure = NULL,
                metric = NULL)]
  
  ## standardise the headings and fix col order
  setnames(dat.v2,
           names(dat.v2),
           tolower(names(dat.v2)))
  setcolorder(dat.v2, c("location", "sex", "age", "year"))
  setorder(dat.v2, location, sex, age, year)
  setnames(dat.v2, c("val", "upper", "lower"), c("pop_count", "pop_count_upper", "pop_count_lower"))
  
  return(dat.v2)
}
