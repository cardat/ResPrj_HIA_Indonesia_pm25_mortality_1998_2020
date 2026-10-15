#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
##
## R targets pipeline for South-east Asia Health Impact Assessment
## using data from 
##     Atmospheric Composition Analysis Group (ACAG) Global PM2.5 (Satellite-derived PM2.5)
##     GADM (administrative boundaries)
##     IHME (all-cause mortality, also population)
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
               "ncdf4",
               "tmap",
               "ggplot2"),
  workspace_on_error = TRUE,
  error = "continue"
)

# TARGETS #
list(
  # Configuration of Scenarios
  tar_target(file_scenarios,
             "scenarios.csv",
             format = "file"),
  tar_target(scenarios, fread(file_scenarios)),
  tar_target(list_scenarios,
             { 
               splits <- split(scenarios, by = c("counterfactual_label"))
               stopifnot(sapply(splits, nrow) == 1)
               return(splits)
               },
             iteration = "list"
             ),
  # Configuration of relative risks
  tar_target(file_RRs,
             "RRs.csv",
             format = "file"),
  tar_target(RRs, fread(file_RRs)),
  tar_target(list_RRs,
             {
               splits <- split(RRs, by = c("RR_label"))
               stopifnot(sapply(splits, nrow) == 1)
               return(splits)
             },
             iteration = "list"
  ),
  
  # DATA INPUTS -------------------------------------------------------------
  
  # Mortality (+ derived population)
  tar_target(file_mortality,
             file.path(indir.mort, infile.mort),
             format = "file"),
  # Population (modelled by province, age, sex)
  tar_target(file_population_age_sex, c(
    file.path(indir.pop.age_sex_male, infile.pop.age_sex_male),
    file.path(indir.pop.age_sex_female, infile.pop.age_sex_female)
  ), format = "file"), 
  
  # Population rasters
  tar_target(file_population,
             file.path(indir.pop, infile.pop),
             format = "file"),
  # Exposure rasters
  tar_target(file_exposure,
             file.path(indir.pm25, infile.pm25),
             format = "file"),
  # Geographical bounds
  tar_target(file_geography,
             file.path(indir.geography, infile.geography),
             format = "file",
             description = "Boundary (polygon) data of spatial study unit"),
  
  # mapping file for province names
  tar_target(file_mapping,
             infile.locname_map,
             format = "file",
             description = "Mapping of IHME to GADM province names"),
  
  # DATA CLEANING/TRANSFORMATION -------------------------------------------
  
  
  ## Clean/tidy initial data inputs ####
  
  ### file_tidy_geography ####
  tar_target(file_tidy_geography,
             do_tidy_geography(file_geography = file_geography, 
                                outfile = out.geography),
             format = "file"),
  
  ### data_tidy_mortality ####
  tar_target(data_tidy_mortality,
             do_tidy_mortality(file_mortality = file_mortality)
             ),
  
  ### data_tidy_mortality_pop ####
  tar_target(data_tidy_mortality_pop,
             do_tidy_mortality_pop(data_tidy_mortality = data_tidy_mortality)
             ),
  
  ### data_tidy_population_age_sex ####
  tar_target(data_tidy_population_age_sex,
             do_tidy_population_age_sex(file_population_age_sex = file_population_age_sex)
  ),
  
  # ANALYSIS ---------------------------------------------------------------
  
  ## Base Exposure ####
  ### data_calc_exposure_by_geography ####
  # Population-weighted mean exposure for spatial units
  tar_target(
    data_baseline_exposure,
    do_baseline_exposure(
      file_exposure = file_exposure,
      file_tidy_geography = file_tidy_geography,
      file_population = file_population
    ),
  ), 
  
  # FOR EACH SCENARIO ---------------------------------------------------------------
  
  ## Construct counterfactuals ####
  
  ### data_construct_counterfactual ####
  ## Set scenario, calculate delta
  tar_target(
    data_counterfactual_exposure,
    do_counterfactual_exposure(
      data_baseline_exposure = data_baseline_exposure,
      scenario = list_scenarios),
    pattern = map(list_scenarios)
  ),
  
  ## Combine dataset inputs ####

  ### data_exposure_health ####
  ## merge exposure and health data
  tar_target(
    data_combined_exposure_response,
    do_combined_exposure_response(
      data_tidy_mortality = data_tidy_mortality,
      data_tidy_mortality_pop = data_tidy_mortality_pop,
      data_baseline_exposure = data_baseline_exposure,
      data_counterfactual_exposure = data_counterfactual_exposure,
      file_mapping = file_mapping
    ),
    pattern = map(data_counterfactual_exposure)
  ),

  
  
  # ## construct response function ###
  # # given relative risks and theoretical minimum risk
  # ### health_impact_function ###
  # tar_target(health_impact_function,
  #            do_health_impact_function(
  #              exposure_response_func = rr,
  #              theoretical_minimum_risk = theoretical_minimum_risk,
  #              unit_change = units_rr_per)
  # ),

  
  
  ## iomlifetR calculations ####

  ### data_mortality_burden ####
  # Calculations of burdens via life expectancy, attributable number and years of life lost with functions from iomlifetR package
  # 
  tar_target(
    data_mortality_burden,
    do_mortality_burden(
      data_combined_exposure_response = data_combined_exposure_response,
      relative_risk = list_RRs
    ),
    pattern = cross(data_combined_exposure_response, list_RRs)
  ),

  ### data_mortality_impact ####
  # Impact of exposure and cessation
  # Calculation of impact from iomlifetR package
  tar_target(data_mortality_impact,
             do_mortality_impact(
               data_combined_exposure_response = data_combined_exposure_response,
               data_tidy_population_age_sex = data_tidy_population_age_sex,
               relative_risk = list_RRs
             ),
             pattern = cross(data_combined_exposure_response, list_RRs),
  ),
  
  ## Bespoke burden calculations ####
  
  ### data_attributable_number ####
  tar_target(data_attributable_number,
             do_attributable_number(
               data_combined_exposure_response = data_combined_exposure_response,
               relative_risk = list_RRs
             ),
             pattern = cross(data_combined_exposure_response, list_RRs))
  
  # # TIDY OUTPUT ---------------------------------------------------------------
  # tar_target(tidy_mortality_results,
  #            do_tidy_mortality_results(
  #              data_mortality_burden,
  #              outdir = "data_derived/mortality"
  #            ), 
  #            format = "file"),
  # tar_target(tidy_popw_mortality_results,
  #            do_tidy_mortality_results(
  #              data_popw_mortality_burden,
  #              outdir = "data_derived/mortality_popw_exp"
  #            ), 
  #            format = "file")#,
  
  # VISUALISE ------------------------------------------------------------
 
  # ### Plot these years in faceted data maps
  # tar_target(qc_yy,
  #            2015:2020),
  # 
  # ## fig_map_inputs ####
  # # Population, mortality, exposure
  # tar_target(fig_map_inputs,
  #            viz_map_inputs(
  #              data_combine_exposure_response = data_combine_exposure_response,
  #              file_tidy_geography = file_tidy_geography,
  #              yy = 2020,
  #              outdir = outdirs$figs_tabs
  #            ),
  #            format = "file",),
  # ## fig_map_inputs_facet ####
  # # Population, mortality, exposure
  # tar_target(fig_map_inputs_facet,
  #            viz_map_inputs_facet(
  #              data_combine_exposure_response = data_combine_exposure_response,
  #              file_tidy_geography = file_tidy_geography,
  #              yy = qc_yy,
  #              outdir = outdirs$figs_tabs
  #            ),
  #            format = "file"),
  # 
  # ## fig_map_attributable_number_alt ####
  # ### from manual calcalation of attributable number
  # tar_target(fig_map_attributable_number_alt,
  #            viz_map_attributable_number_alt(
  #              data_attributable_number_alt = data_attributable_number_alt,
  #              file_tidy_geography = file_tidy_geography,
  #              yy = qc_yy,
  #              outdir = outdirs$figs_tabs
  #            ),
  #            format = "file"
  # ),
  # 
  # ## fig_map_attributable_number ####
  # ### from iomlifetR function for attributable number
  # tar_target(fig_map_attributable_number,
  #            viz_map_attributable_number(
  #              data_combine_exposure_response = data_combine_exposure_response, 
  #              data_attributable_number = data_attributable_number,
  #              file_tidy_geography = file_tidy_geography,
  #              yy = qc_yy,
  #              outdir = outdirs$figs_tabs
  #            ),
  #            format = "file"
  # ),
  

  # REPORTS --------------------------------------------------------------
  
  ## report ####
  # render an Rmarkdown report of the HIA
  # tar_quarto(report_summary, 
  #            "report/report_summary.qmd", 
  #            quiet = F
  #            ),
  # tar_quarto(report_qc, 
  #            "report/report_qc.qmd", 
  #            quiet = F
  # )
  
  
  
  ## report_targets ####
  # render a summary of pipeline status
  # always run this target (has no dependency on another target)
  # tar_render(report_targets, "report/report_pipeline_status.Rmd",
  #            cue = tar_cue("always"))
  
)

 
