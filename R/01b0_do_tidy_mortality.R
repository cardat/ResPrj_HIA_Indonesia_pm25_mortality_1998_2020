# targets::tar_workspace(data_tidy_mortality)

do_tidy_mortality <- function(file_mortality){
  
  dat <- fread(file_mortality)
  
  # Subset data ####
  # strip out ID fields
  dat2 <- dat[, .(measure_name, location_name, sex_name, age_name, cause_name, metric_name, year, val)]
  setnames(dat2, names(dat2), gsub("_name$", "", names(dat2)))
  
  # subset records to the 5yr age groups and male/female
  sel_agegroups <- seq(5, 90, 5)
  sel_agegroups <- c("<5 years",
                     sprintf("%i-%i years", sel_agegroups, sel_agegroups+4),
                     "95+ years")
  dat2 <- dat2[sex %in% c("Male", "Female") &
                    age %in% sel_agegroups]
  dat2[, age := factor(age, levels = sel_agegroups)]

  # estimate population ####
  dat3 <- data.table::dcast(dat2, ... ~ metric, value.var = c("val"))
  
  ## standardise the headings
  setnames(dat3,
           names(dat3),
           tolower(names(dat3)))
  
  return(dat3)
}
