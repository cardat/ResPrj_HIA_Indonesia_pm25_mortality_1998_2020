##%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
##
## Construct and run a Health Impact Assessment (HIA) pipeline
##
##%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

# Load libraries and functions --------------------------------------------
library(targets)

# Run pipeline ------------------------------------------------------------
## visualise targets
tar_glimpse()
tar_manifest() # or get a tibble

## run pipeline
tar_make()

# View pipeline status

## visualise target status
# click a target to highlight linked targets (use argument degree_to/degree_from to control number of edges to highlight, default 1)
tar_visnetwork(targets_only = T) |>
  visNetwork::visHierarchicalLayout(direction = "UD", nodeSpacing = 200)

## Alternative layout
tar_visnetwork(targets_only = T) |>
  visNetwork::visIgraphLayout(layout = "layout_nicely", physics = T, smooth = T)
  



# View target output ------------------------------------------------------

## table
# see results of specified target
tar_read(data_attributable_number)

## view report
browseURL("report.html")


# Debugging help ----------------------------------------------------------

tar_meta(fields = warnings, complete_only = T)
tar_meta(fields = error, complete_only = T)
