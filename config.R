# Define key outputs ------------------------------------------------------
runDate <- strftime(Sys.Date(), "%Y%m%d")

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
indir.geography <- file.path(
  datadir,
  "CAR_staging_area",
  "data_sharing/uploads_from_ivan/GADM_Global_Administrative_Areas/data_provided/"
)
infile.geography <- "gadm404-levels.gpkg"

indir.mort <- file.path(
  datadir,
  "CAR_staging_area",
  "IHME_GBD_2021/IHME_GBD_2021_all_cause_mortality_SEA_1998_2021/data_provided/"
)
infile.mort <- "IHME-GBD_2021_DATA-SEA_all_cause_mortality.csv"

indir.pm25 <- file.path(
  datadir,
  "Environment_General",
  "Air_pollution_model_GlobalGWR_PM25/GlobalGWR_PM25_V5GL02_1998_2020/data_provided/GWRPM25/Annual"
)
infile.pm25 <- sprintf("V5GL02.HybridPM25.Global.%04i01-%04i12.nc",
                       yys_todo,
                       yys_todo)

infile.locname_map <- "metadata/ihme_gadm_locname_map.csv"

# PARAMETERS ####

# Relative risk
rr <- 1.06
