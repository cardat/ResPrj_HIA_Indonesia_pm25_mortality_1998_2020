library(httr2)
library(rvest)

BASE_URL <- "https://data.worldpop.org/GIS"
DATA_TYPE <- "Population"
DATASET <- "Global_2000_2020_1km" # Global_2000_2020_1km or Global_2000_2020_1km_UNadj
COUNTRY_CODE <- "IDN"

outdir <- "data_provided/WorldPop"

# Request directory listing ####
req <- httr2::request(BASE_URL) |>
  httr2::req_url_path_append(DATA_TYPE, DATASET)

resp <- req_perform(req)

html <- resp_body_html(resp)

child_dirs <- rvest::html_attr(rvest::html_elements(html, "table tr td a"), "href")
child_dirs

# list only yearly directories
yys <- setdiff(child_dirs, "/GIS/Population/")
yys <- gsub("/$", "", yys)

# Download each year ####
for (yy in yys){
  # yy <- yys[1]
  req_yy <- req |>
    httr2::req_url_path_append(yy, COUNTRY_CODE)
  resp_yy <- req_perform(req_yy)
  html_yy <- resp_body_html(resp_yy)
  
  # what files linked in directory?
  children <- rvest::html_attr(rvest::html_elements(html_yy, "table tr td a"), "href")
  
  # get the GeoTiff, ensure only one file shown
  file_get <- grep("tif$", children, value = T)
  stopifnot(length(file_get) == 1)
  
  # Download
  outfile_yy <- file.path(outdir, DATASET, COUNTRY_CODE, file_get)
  if(!dir.exists(dirname(outfile_yy))) dir.create(dirname(outfile_yy), recursive = T)
  
  req_yy |>
    httr2::req_url_path_append(file_get) |>
    req_progress() |>
    req_perform(path = outfile_yy, verbosity = 1)
  Sys.sleep(5)
}
