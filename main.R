##%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
##
## Construct and run a Health Impact Assessment (HIA) pipeline
##
##%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

# Load libraries and functions --------------------------------------------
library(targets)


# Examine pipeline --------------------------------------------------------

# See targets
tar_manifest()

# View pipeline status

# click a target to highlight linked targets (use argument degree_to/degree_from to control number of edges to highlight, default 1)
tar_visnetwork(targets_only = T) |>
  visNetwork::visHierarchicalLayout(direction = "UD", nodeSpacing = 200)

## Alternative layout
tar_visnetwork(targets_only = T) |>
  visNetwork::visIgraphLayout(layout = "layout_nicely", physics = T, smooth = T)



# Run pipeline ------------------------------------------------------------

## run pipeline
tar_make()


# View target output ------------------------------------------------------

## table
# see results of specified target
tar_read(data_attributable_number)

## view report
browseURL(tar_read(report)[1])


# Debugging help ----------------------------------------------------------

# show the warnings
tar_meta(fields = warnings, complete_only = T)

# or the errors
tar_meta(fields = error, complete_only = T)

# or show all target metadata
tar_meta()
