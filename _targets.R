#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
##
## R targets pipeline for South-east Asia Health Impact Assessment
## using data from 
##     Atmospheric Composition Analysis Group (ACAG) Global PM2.5 (Satellite-derived PM2.5)
##     GADM (administrative boundaries)
##     IHME (all-cause mortality, also derived population)
## 
## Cassandra Yuen (2025-07-03)
##
#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

library(targets)
library(tarchetypes)

# Define global variables -------------------------------------------------
source('config.R')

# Load custom functions ---------------------------------------------------
tar_source()

# Set targets options -----------------------------------------------------

tar_option_set(
  packages = c("sf", # packages to load before target builds
               "terra",
               "data.table",
               "iomlifetR",
               "leaflet",
               "ggplot2"),
  error = "continue"
)

# TARGETS #
list(
  # DATA INPUTS -------------------------------------------------------------
  
  # Mortality
  tar_target(file_mortality,
             file.path(indir.mort, infile.mort),
             format = "file"),
  # Exposure rasters
  tar_target(file_exposure,
             file.path(indir.pm25, infile.pm25),
             format = "file"),
  # Geographical bounds
  tar_target(file_geography,
             file.path(indir.geography, infile.geography),
             format = "file"),
  
  # mapping file for province names
  tar_target(file_mapping,
             "metadata/ihme_gadm_locname_map.csv",
             format = "file"),
  
  
  # DATA CLEANING/TRANSFORMATION -------------------------------------------
  
  
  ## Clean/tidy initial data inputs ####
  
  ### file_tidy_geography ####
  tar_target(file_tidy_geography,
             do_tidy_geography(file_geography = file_geography, 
                                outfile = out.geography),
             format = "file"),
  
  ### data_tidy_mortality ####
  tar_target(data_tidy_mortality,
             do_tidy_mortality(file_mortality = file_mortality)),
  
  ### data_tidy_mortality_pop ####
  tar_target(data_tidy_mortality_pop,
             do_tidy_mortality_pop(data_tidy_mortality = data_tidy_mortality)),
  
  ### data_calculate_exposure_by_geography ####
  tar_target(
    data_calc_exposure_by_geography,
    do_calc_exposure_by_geography(
      file_exposure = file_exposure,
      file_tidy_geography = file_tidy_geography,
      variable_name = "pm25"
    )
  ), 
  
  
  ## Counterfactual scenario ####
  
  ### data_make_counterfactual ####
  ## Set scenario, calculate delta
  tar_target(
    data_construct_counterfactual,
    do_construct_counterfactual(data_calc_exposure_by_geography = data_calc_exposure_by_geography,
                                counterfactual_type = "abs",
                                counterfactual_value = 10)
  ),
  
  
  ## Combine dataset inputs ####
  
  ### data_combine_exposure_response ####
  ## merge exposure and health data
  tar_target(
    data_combine_exposure_response,
    do_combine_exposure_response(
      data_tidy_mortality = data_tidy_mortality,
      data_tidy_mortality_pop = data_tidy_mortality_pop,
      data_calc_exposure_by_geography = data_calc_exposure_by_geography, 
      data_construct_counterfactual = data_construct_counterfactual,
      file_mapping = file_mapping
    ),
    format = "file"
  ), 

    
  # ANALYSIS ---------------------------------------------------------------
  
  ### construct response function #### 
  ## given relative risks and theoretical minimum risk
  #### health_impact_function ####
  tar_target(health_impact_function,
             do_health_impact_function(
               case_definition = 'crd',
               exposure_response_func = c(1.06, 1.02, 1.08),
               theoretical_minimum_risk = 0
               )
  ),
  
  ## calculate health impacts ####
  ### data_attributable_number ####
  tar_target(data_attributable_number,
             do_attributable_number(
               hif = health_impact_function,
               data_combine_exposure_response = data_combine_exposure_response,
               minimum_age = 30
             ),
             format = "file"
  ),
  ### data_life_tables ####
  tar_target(data_life_tables,
             do_life_tables(
               data_combine_exposure_response = data_combine_exposure_response
             ),
             format = "file"
  ),
  
  # VISUALISE ------------------------------------------------------------
  tar_target(fig_attributable_number,
             viz_attributable_number(
               data_attributable_number = data_attributable_number,
               file_tidy_geography = file_tidy_geography
             ),
             format = "file"
  )#
  
  
  # REPORTS --------------------------------------------------------------
  # render a summary of pipeline
  # tar_render(report_targets, "rmarkdown/report_targets.Rmd")
  
  # render report
)

 
## Visualise OLD
# 
# viz <- list(
#   # create map of attributable number, faceted by year (with ggplot2)
#   tar_target(
#     viz_an,
#     {
#       # summarise data and merge with spatial for plotting
#       dat_an <- calc_attributable_number
#       dat_an <- dat_an[,.(pop_tot = sum(pop_study, na.rm = T),
#                           expected_tot = sum(expected, na.rm = T),
#                           attributable = sum(attributable, na.rm = T),
#                           pm25_cf_pw_sa2 = mean(v1, na.rm = T),
#                           pm25_pw_sa2 = mean(x, na.rm = T)),
#                        by = .(sa2_main16, year)]
#       sf_an <- tidy_geom_sa2_2016
#       sf_an <- merge(sf_an, dat_an)
#       viz_map_an(sf_an)
#     }
#   ),
#   
#   # leaflet map of attributable number, summed over SA2s, averaged over years (with leaflet)
#   tar_target(
#     leaflet_an,
#     {
#       # get and summarise data
#       dat_an <- calc_attributable_number
#       dat_an <- dat_an[,.(pop_tot = sum(pop_study, na.rm = T),
#                           expected_tot = sum(expected, na.rm = T),
#                           attributable = sum(attributable, na.rm = T),
#                           pm25_cf = mean(v1, na.rm = T),
#                           pm25 = mean(x, na.rm = T)),
#                        by = .(sa2_main16, year)]
#       # aggregate over years (mean)
#       dat_an <- dat_an[,.(pop_tot = mean(pop_tot),
#                           expected_tot = mean(expected_tot),
#                           attributable = mean(attributable),
#                           pm25_cf = mean(pm25_cf),
#                           pm25 = mean(pm25)),
#                        by = .(sa2_main16)]
#       
#       # merge with spatial for plotting
#       sf_an <- merge(tidy_geom_sa2_2016, dat_an)
#       sf_an <- st_simplify(sf_an, dTolerance = 75)
#       viz_leaflet_an(sf_an)
#     }
#   ),
#   
    
#   # render an Rmarkdown report
#   tar_render(report, "report.Rmd")
# )
