# Compare modelled annual exposure from various ACAG dataset versions

# See https://www.satpm.org/, linked from ACAG website at https://sites.wustl.edu/acag/

# V4GL02 as originally used by Josh Horsley in pilot HIA study
# V5GL02 as kept in CARDAT
# V5GL06 as downloaded from ACAG (recent version with geographically weighted regression)
# V6GL03 as downloaded from ACAG (recent version with convolutional neural network)

library(targets)
library(terra)
library(data.table)

# INPUT DATA ####

indirs <- list(V4GL02 = "data_provided/ACAG/V4GL02/",
               V5GL02 = "~/CARDAT/Environment_General/Air_pollution_model_GlobalGWR_PM25/GlobalGWR_PM25_V5GL02_1998_2020/data_provided/GWRPM25/Annual/",
               V5GL06 = "data_provided/ACAG/V5GL06/",
               V6GL03 = "data_provided/ACAG/V6GL03/")

yys <- seq(2000, 2020, 5)

# READ AND PREP DATA ####
fs <- lapply(indirs, list.files, full.names = T)

fs_yy <- lapply(yys, function(yy) sapply(fs, function(x) x[grepl(yy, basename(x))]))
names(fs_yy) <- yys


## Visualise ####
v <- vect(tar_read(file_tidy_geography))
          
for (yy in names(fs_yy)){
  # yy <- "2000"
  i <- fs_yy[[yy]]
  
    
  r <- lapply(i, function(x) {
    
    if(length(x) == 0){
      return(rast(nrow = 10, ncol = 10, nlyrs = 1, vals = NA))
    }
    
    # read in and crop to Indonesia
    if(grepl("V5GL02", x)){
      r_x <- crop(rast(x, noflip = T), ext(v))
    } else {
      r_x <- crop(rast(x), ext(v))
    }
    
    if(grepl("V6GL03", x)) {
      NAflag(r_x) <- -999
    }
    
    return(r_x)
  })
  
  # resample to match last raster
  r_resampled <- lapply(r, resample, y = r[[length(r)]])
  r_resampled <- rast(r_resampled)
  varnames(r_resampled) <- sprintf("PM25 %s", names(r_resampled))
  
  # mask to geographical boundaries
  r_resampled.v2 <- mask(r_resampled, v)
  panel(r_resampled.v2)
  title(main = yy, outer = T)
}

