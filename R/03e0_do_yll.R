# targets::tar_workspace(data_yll)

do_yll <- function(
    data_attributable_number,
    data_le
){
  
  data_attributable_number
  data_le
  
  # calculate years of life lost
  dat_yll <- iomlifetR::burden_yll(
    attributable_number = data_attributable_number,
    life_expectancy = data_le[["impacted"]][, "ex"]
  )
  
  return(dat_yll)
}
