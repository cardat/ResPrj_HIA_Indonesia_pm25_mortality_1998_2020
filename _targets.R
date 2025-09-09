#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
##
## R targets pipeline for South-east Asia Health Impact Assessment
## using data from 
##     Atmospheric Composition Analysis Group (ACAG) Global PM2.5 (Satellite-derived PM2.5)
##     GADM (administrative boundaries)
##     IHME (all-cause mortality, also derived population)
## 
## 
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
  # packages to load before target builds
  packages = c("sf", 
               "terra",
               "data.table",
               "iomlifetR",
               "tmap"),
  workspace_on_error = TRUE,
  workspaces = "data_attributable_number",
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
             infile.locname_map,
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
  
  ### data_calc_exposure_by_geography ####
  tar_target(
    data_calc_exposure_by_geography,
    do_calc_exposure_by_geography(
      file_exposure = file_exposure,
      file_tidy_geography = file_tidy_geography,
      variable_name = "pm25"
    )
  ), 
  
  
  ## Counterfactual scenario ####
  
  ### data_construct_counterfactual ####
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
      # data_calc_exposure_by_geography = data_calc_exposure_by_geography, 
      data_construct_counterfactual = data_construct_counterfactual,
      file_mapping = file_mapping
    )
  ), 
  tar_target(
    file_combine_exposure_response,
    fwrite(data_combine_exposure_response, out.combined_data),
    format = "file"
  ),

    
  # ANALYSIS ---------------------------------------------------------------
  
  ### construct response function #### 
  ## given relative risks and theoretical minimum risk
  #### health_impact_function ####
  tar_target(health_impact_function,
             do_health_impact_function(
               exposure_response_func = rr,
               theoretical_minimum_risk = theoretical_minimum_risk,
               unit_change = units_rr_per)
  ),
  
  ## calculate health impacts ####
  ### data_attributable_number_alt ####
  # manual calculation of attributable number
  tar_target(data_attributable_number_alt,
             do_attributable_number_alt(
               hif = health_impact_function,
               data_combine_exposure_response = data_combine_exposure_response,
               minimum_age = 30
             )
  ),
  
  ### data_attributable_number ####
  # attributable number from iomlifetR
  tar_target(data_attributable_number,
             do_attributable_number(
               data_combine_exposure_response = data_combine_exposure_response
             )
  ),
  
  
  ### data_life_tables ####
  # life tables from iomlifetR
  tar_target(data_life_table,
             do_life_table(
               data_combine_exposure_response = data_combine_exposure_response
             )
  ),
  ### data_le ####
  # life expectancy from iomlifetR
  tar_target(data_le,
             do_le(
               data_combine_exposure_response = data_combine_exposure_response
             )
  ),
  
  ### data_yll ####
  # years of life lost from iomlifetR
  tar_target(data_yll,
             do_yll(
               data_attributable_number = data_attributable_number,
               data_le = data_le
             )
  ),
  
  # VISUALISE ------------------------------------------------------------
 
  ### Plot these years in faceted data maps
  tar_target(qc_yy,
             2015:2020),
  
  ## fig_map_inputs ####
  # Population, mortality, exposure
  tar_target(fig_map_inputs,
             viz_map_inputs(
               data_combine_exposure_response = data_combine_exposure_response,
               file_tidy_geography = file_tidy_geography,
               yy = 2020,
               outdir = outdirs$figs_tabs
             ),
             format = "file",),
  ## fig_map_inputs_facet ####
  # Population, mortality, exposure
  tar_target(fig_map_inputs_facet,
             viz_map_inputs_facet(
               data_combine_exposure_response = data_combine_exposure_response,
               file_tidy_geography = file_tidy_geography,
               yy = qc_yy,
               outdir = outdirs$figs_tabs
             ),
             format = "file"),
  
  ## fig_map_attributable_number_alt ####
  ### from manual calcalation of attributable number
  tar_target(fig_map_attributable_number_alt,
             viz_map_attributable_number_alt(
               data_attributable_number_alt = data_attributable_number_alt,
               file_tidy_geography = file_tidy_geography,
               yy = qc_yy,
               outdir = outdirs$figs_tabs
             ),
             format = "file"
  ),
  
  ## fig_map_attributable_number ####
  ### from iomlifetR function for attributable number
  tar_target(fig_map_attributable_number,
             viz_map_attributable_number(
               data_combine_exposure_response = data_combine_exposure_response, 
               data_attributable_number = data_attributable_number,
               file_tidy_geography = file_tidy_geography,
               yy = qc_yy,
               outdir = outdirs$figs_tabs
             ),
             format = "file"
  ),
  

  # REPORTS --------------------------------------------------------------
  ## report_targets ####
  # render a summary of pipeline status
  tar_render(report_targets, "pipeline_status/report_pipeline_status.Rmd"),
  
  ## report ####
  # render an Rmarkdown report of the HIA
  tar_render(report, "report/report.Rmd")
  
)

 
