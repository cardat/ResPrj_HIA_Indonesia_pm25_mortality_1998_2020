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
               "ncdf4",
               "tmap",
               "ggplot2"),
  workspace_on_error = TRUE,
  workspaces = "data_calc_popw_exposure_by_geography",
  error = "continue"
)

# TARGETS #
list(
  # DATA INPUTS -------------------------------------------------------------
  
  # Mortality (+ derived population)
  tar_target(file_mortality,
             file.path(indir.mort, infile.mort),
             format = "file", 
             description = "Mortality data"),
  # Population rasters
  tar_target(file_population,
             file.path(indir.pop, infile.pop),
             format = "file",
             description = "Population data"),
  # Exposure rasters
  tar_target(file_exposure,
             file.path(indir.pm25, infile.pm25),
             format = "file",
             description = "Exposure data"),
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
             description = "Subset geographical boundaries data",
             do_tidy_geography(file_geography = file_geography, 
                                outfile = out.geography),
             format = "file"),
  
  ### data_tidy_mortality ####
  tar_target(data_tidy_mortality,
             description = "Clean and reformat mortality data",
             do_tidy_mortality(file_mortality = file_mortality)
             ),
  
  ### data_tidy_mortality_pop ####
  tar_target(data_tidy_mortality_pop,
             description = "Derive, clean and reformat population data from mortality rates",
             do_tidy_mortality_pop(data_tidy_mortality = data_tidy_mortality)
             ),
  
  ## Base Exposure ####
  ### data_calc_exposure_by_geography ####
  tar_target(
    data_calc_exposure_by_geography,
    description = "Extract unweighted and pop-weighted mean exposure for each spatial unit",
    do_calc_exposure_by_geography(
      file_exposure = file_exposure,
      file_tidy_geography = file_tidy_geography,
      file_population = file_population
    ),
  ), 
  
  ## Counterfactual scenario ####
  # Dynamically-mapped
  
  ### table_counterfactual_scenarios ####
  tarchetypes::tar_group_by(table_counterfactual_scenarios,
                            counterfactuals_todo, 
                            scenario),
  ### data_construct_counterfactual ####
  ## Set scenario, calculate delta
  tar_target(
    data_construct_counterfactual,
    do_construct_counterfactual(
      data_calc_exposure_by_geography = data_calc_exposure_by_geography[exposure_aggregation == "mean"],
      cf_scenario = table_counterfactual_scenarios),
    pattern = map(table_counterfactual_scenarios)
  ),
  
  ### data_construct_popw_counterfactual ####
  ## Set scenario, calculate delta
  tar_target(
    data_construct_popw_counterfactual,
    do_construct_counterfactual(
      data_calc_exposure_by_geography = data_calc_exposure_by_geography[exposure_aggregation == "population-weighted mean"],
      cf_scenario = table_counterfactual_scenarios),
    pattern = map(table_counterfactual_scenarios)
  ),
  
  
  ## Combine dataset inputs ####
  
  ### data_combine_exposure_response ####
  ## merge exposure and health data
  tarchetypes::tar_group_by(
    data_combine_exposure_response,
    do_combine_exposure_response(
      data_tidy_mortality = data_tidy_mortality,
      data_tidy_mortality_pop = data_tidy_mortality_pop,
      data_calc_exposure_by_geography = data_calc_exposure_by_geography[exposure_aggregation == "mean"],
      data_construct_counterfactual = data_construct_counterfactual,
      file_mapping = file_mapping
    ),
    counterfactual_scenario
  ),
  # save as csv
  tar_target(
    file_combine_exposure_response,
    fwrite(data_combine_exposure_response, out.combined_data),
    format = "file"
  ),
  
  ### data_combine_popw_exposure_response ####
  ## merge exposure and health data
  tarchetypes::tar_group_by(
    data_combine_popw_exposure_response,
    do_combine_exposure_response(
      data_tidy_mortality = data_tidy_mortality,
      data_tidy_mortality_pop = data_tidy_mortality_pop,
      data_calc_exposure_by_geography = data_calc_exposure_by_geography[exposure_aggregation == "population-weighted mean"],
      data_construct_counterfactual = data_construct_popw_counterfactual,
      file_mapping = file_mapping
    ),
    counterfactual_scenario
  ), 
  # save as csv
  tar_target(
    file_combine_popw_exposure_response,
    fwrite(data_combine_popw_exposure_response, gsub("combined", "popw_combined", out.combined_data)),
    format = "file"
  ),

    
  # ANALYSIS ---------------------------------------------------------------
  
  ### construct response function #### 
  ## given relative risks and theoretical minimum risk
  #### health_impact_function ####
  # tar_target(health_impact_function,
  #            do_health_impact_function(
  #              exposure_response_func = rr,
  #              theoretical_minimum_risk = theoretical_minimum_risk,
  #              unit_change = units_rr_per)
  # ),
  
  ### iomlifetR calculations ####
  
  
  #### Mortality burden ####
  # Calculations of burdens via life expectancy, attributable number and years of life lost with functions from iomlifetR package
  tar_group_by(
    RRs,
    RRs_todo,
    label
  ),
  
  tar_target(
    data_mortality_burden,
    do_mortality_burden(
      data_combine_exposure_response = data_combine_exposure_response,
      relative_risk = RRs$value,
      relative_risk_label = RRs$label
    ),
    pattern = cross(data_combine_exposure_response, RRs),
    iteration = "list"
  ),
  
  # Calculations of burdens via life expectancy, attributable number and years of life lost with functions from iomlifetR package
  tar_target(
    data_popw_mortality_burden,
    do_mortality_burden(
      data_combine_exposure_response = data_combine_popw_exposure_response,
      relative_risk = RRs$value,
      relative_risk_label = RRs$label
    ),
    pattern = cross(data_combine_popw_exposure_response, RRs),
    iteration = "list"
  ),
  
  #### Impact of exposure and cessation ####
  # Calculation of impact from iomlifetR package
  # tar_target(data_popw_impact,
  #            do_mortality_impact(
  #              data_combine_exposure_response = data_combine_popw_exposure_response
  #            ),
  # ),
  # 
  
  # TIDY OUTPUT ---------------------------------------------------------------
  tar_target(summarise_mortality_results,
             do_summarise_mortality_results(
               data_mortality_burden,
               outdir = "data_derived/mortality"
             ), 
             format = "file"),
  tar_target(summarise_popw_mortality_results,
             do_summarise_mortality_results(
               data_popw_mortality_burden,
               outdir = "data_derived/mortality_popw_exp"
             ), 
             format = "file"),
  
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
  tar_quarto(report_summary, 
             "report/report_summary.qmd", 
             quiet = F
             ),
  tar_quarto(report_qc, 
             "report/report_qc.qmd", 
             quiet = F
  )
  
  
  
  ## report_targets ####
  # render a summary of pipeline status
  # always run this target (has no dependency on another target)
  # tar_render(report_targets, "report/report_pipeline_status.Rmd",
  #            cue = tar_cue("always"))
  
)

 
