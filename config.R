# Define key outputs ------------------------------------------------------
# suffix identifier to output file names
runDate <- "20260625"

outdir <- "data_derived"

# geographical boundaries and combined input data
out.geography <- file.path(outdir, sprintf("IDN_provinces_%s.gpkg", runDate))
out.combined_data <- file.path(outdir, sprintf("IDN_combined_data_%s.csv", runDate))

# final HIA output
out.hia_an <- file.path(outdir, sprintf("IDN_attributable_number_%s.csv", runDate))
out.hia_life_tables <- file.path(outdir, sprintf("IDN_life_tables_%s.csv", runDate))

# Define parameters -------------------------------------------------------
# YEARS - range between 1998 and 2020 (years of obtained data)
yys_todo <- 1998:2020

# Define input data paths -------------------------------------------------
datadir <- "~/CARDAT/"
# Geographical boundaries
indir.geography <- file.path(
  datadir,
  "CAR_staging_area",
  "data_sharing/uploads_from_ivan/GADM_Global_Administrative_Areas/data_provided/"
)
infile.geography <- "gadm404-levels.gpkg"

# Mortality
indir.mort <- file.path(
  datadir,
  "CAR_staging_area",
  "IHME_GBD_2021/IHME_GBD_2021_all_cause_mortality_SEA_1998_2021/data_provided/"
)
infile.mort <- "IHME-GBD_2021_DATA-SEA_all_cause_mortality.csv"

# Population
indir.pop <- file.path(
  "data_provided",
  "WorldPop_Population_Density/Global_2000_2020_1km/IDN/"
)
infile.pop <- list.files(indir.pop, pattern = "tif$")

# Exposure
indir.pm25 <- file.path(
  datadir,
  "Environment_General",
  "Air_pollution_model_GlobalGWR_PM25/GlobalGWR_PM25_V5GL02_1998_2020/data_provided/GWRPM25/Annual"
)
infile.pm25 <- sprintf("V5GL02.HybridPM25.Global.%04i01-%04i12.nc",
                       yys_todo,
                       yys_todo)

#manually created mapping file of IHME province names, GADM province names (Indonesian and English)
infile.locname_map <- "data_provided/ihme_gadm_locname_map.csv"

# Output paths ------------------------------------------------------------
outdirs <- list(data = "data_derived",
                figs_tabs = "figs_and_tabs",
                qc = "qc")


# GLOBAL COLUMN IDENTIFIERS -------------------------------------------------------------
spatial_ID <- c("province") # spatial study unit ID column(s) - unique, for joining

# PARAMETERS --------------------------------------------------------------

# Exposure of interest ####
exposure_label <- "pm25"

# Counterfactual scenarios ####
counterfactuals_todo <- data.table::rbindlist(list(
  list(
    scenario = "WHO AQG level", 
    scenario_type = "abs", # for counterfactual construction function
    scenario_value = 5 # for counterfactual construction function
  ),
  list(
    scenario = "WHO Interim Target 4", 
    scenario_type = "abs",
    scenario_value = 10
  ),
  list(
    scenario = "WHO Interim Target 3", 
    scenario_type = "abs",
    scenario_value = 15
  )
))

# counterfactual_scenario_type <- "abs" # absolute / relative / modelled CTM concentrations
# counterfactual_scenario <- 10

# Relative risk ####
# from WHO Health risks of air pollution in Europe (HRAPIE) project recommendations (https://iris.who.int/handle/10665/153692)
# Published in Hoek, et al. (2013), available at https:/doi.org/10.1186/1476-069x-12-43

# Table of relative risks with label
# RRs from HRAPIE project, and upper (uci) and lower (lci) confidence intervals
RRs_todo <- data.table::data.table(
  label = c("rr_hrapie", "rr_hrapie_uci", "rr_hrapie_lci"),
  value = c(1.062, 1.040, 1.083)
)

# relative risk per x units change
units_rr_per <- 10
theoretical_minimum_risk <- 0

# minimum age at risk
minimum_age_risk <- 30



