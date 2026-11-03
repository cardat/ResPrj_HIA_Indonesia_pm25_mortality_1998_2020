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
datadir_staging <- "~/../OneDrive - Curtin/cloud-car-dat_staging"
datadir <- "~/../Nextcloud/Shared/"
# Geographical boundaries
indir.geography <- file.path(
  datadir,
  "Environment_General",
  "GADM_Global_Administrative_Areas/GADM_404_Global/data_provided/"
)
infile.geography <- "gadm404-levels.gpkg"

# Mortality
indir.mort <- file.path(
  datadir_staging,
  "IHME_GBD_2021/IHME_GBD_2021_all_cause_mortality_SEA_1998_2021/data_provided/"
)
infile.mort <- "IHME-GBD_2021_DATA-SEA_all_cause_mortality.csv"

# Total modelled population raster
indir.pop <- file.path(
  "data_provided",
  "WorldPop_Population_Density/Global_2000_2020_1km/IDN/"
)
infile.pop <- list.files(indir.pop, pattern = "tif$")

# Modelled population by province, age and sex (IHME)
indir.pop.age_sex_male <- file.path(
  datadir_staging, "IHME_GBD_2023/IHME_GBD_2023_population_IDN_1998_2023/data_provided"
  )
infile.pop.age_sex_male <- "IHME-GBD_2023_DATA_IDN_population_male_1998_2023.csv"
  
indir.pop.age_sex_female <- file.path(
  datadir_staging, "IHME_GBD_2021/IHME_GBD_2021_population_IDN_1998_2021/data_provided"
)
infile.pop.age_sex_female <- "IHME-GBD_2021_DATA_IDN_population_female_1998_2021.csv"

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

# minimum age at risk
minimum_age_risk <- 30
