#' do_tidy_mortality
#'
#' Clean raw mortality data. Output death count by measure, province, sex, age, cause and year. Death rate required for calculation of estimated population - if other source of population data available, death rate not required.
#'
#' @param file_mortality File path to raw mortality data
#'
#' @returns data.table of mortality data with fields measure, province, sex, age, cause, year, number (count) and rate
do_tidy_mortality <- function(file_mortality){
  
  dat <- fread(file_mortality)
  
  # Subset data ####
  # clean up headings
  dat2 <- dat[, .(measure_name, location_name, sex_name, age_name, cause_name, metric_name, year, val)]
  setnames(dat2, names(dat2), gsub("_name$", "", names(dat2)))
  # set jurisdictional level heading
  setnames(dat2, "location", "province")
  
  # subset records to the 5yr age groups and male/female
  sel_agegroups <- seq(5, 90, 5)
  sel_agegroups <- c("<5 years",
                     sprintf("%i-%i years", sel_agegroups, sel_agegroups+4),
                     "95+ years")
  dat2 <- dat2[sex %in% c("Male", "Female") &
                    age %in% sel_agegroups]
  dat2[, age := factor(age, levels = sel_agegroups)]

  # cast mortality number (count) and rate
  dat3 <- data.table::dcast(dat2, as.formula("... ~ metric"), value.var = c("val"))
  
  ## standardise the headings
  setnames(dat3,
           names(dat3),
           tolower(names(dat3)))
  
  return(dat3)
}
