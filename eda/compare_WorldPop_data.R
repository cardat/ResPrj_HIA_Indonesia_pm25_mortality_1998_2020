# Compare annual population estimates from IHME and those from WorldPop datasets
# WorldPop can be adjusted to align with UN estimates or not

library(targets)
library(terra)
library(data.table)

# INPUT DATA ####
indir_WorldPop_UNadj <- "data_provided/WorldPop/Global_2000_2020_1km_UNadj"  # adjusted to fit UN estimates
indir_WorldPop <- "data_provided/WorldPop/Global_2000_2020_1km" # not adjusted

# READ AND PREP DATA ####

## Geographical boundaries ####
v <- vect(tar_read(file_tidy_geography))

## IHME data ####
pop_ihme <- tar_read(data_tidy_mortality_pop)
map_ihme <- fread(tar_read(file_mapping))
# join map to province name in Indonesian
dat_ihme <- pop_ihme[, .(province, year, sex, age, pop)]
dat_ihme[map_ihme, on = .(province = location), province := i.province]


## WorldPop adjusted ####
fs_WorldPop_UNadj <- list.files(indir_WorldPop_UNadj, pattern = "tif$", recursive = T)

# as raster
r_WorldPop_UNadj <- rast(file.path(indir_WorldPop_UNadj, fs_WorldPop_UNadj))
time(r_WorldPop_UNadj) <- as.integer(gsub(".+ppp_([0-9]{4})_1km.+", "\\1", basename(fs_WorldPop_UNadj)))
names(r_WorldPop_UNadj) <- sprintf("pop_count_UNadj_%i", time(r_WorldPop_UNadj))
# r_WorldPop_UNadj


## WorldPop ####
fs_WorldPop <- list.files(indir_WorldPop, pattern = "tif$", recursive = T)

# as raster
r_WorldPop <- rast(file.path(indir_WorldPop, fs_WorldPop))
time(r_WorldPop) <- as.integer(gsub(".+ppp_([0-9]{4})_1km.+", "\\1", basename(fs_WorldPop)))
names(r_WorldPop) <- sprintf("pop_count_UNadj_%i", time(r_WorldPop))
r_WorldPop


# EXTRACT TO PROVINCE ####
e <- extract(r_WorldPop_UNadj, v, fun = "sum", na.rm = T, weights = T, ID = F)
setDT(e)
e[, province := v$province]
dat_WP_UNadj <- melt(e, id.vars = "province", variable.name = "year", variable.factor = F, value.name = "WorldPop_UNadj")
dat_WP_UNadj[, year := as.integer(gsub("[A-Za-z_]+_", "", year))]

  
e2 <- extract(r_WorldPop, v, fun = "sum", na.rm = T, weights = T, ID = F)
setDT(e2)
e2[, province := v$province]
dat_WP <- melt(e2, id.vars = "province", variable.name = "year", variable.factor = F, value.name = "WorldPop")
dat_WP[, year := as.integer(gsub("[A-Za-z_]+_", "", year))]

dat_pops <- dat_ihme[, .(IHME = sum(pop)), by = .(province, year)]
dat_pops <- dat_pops[dat_WP_UNadj, on = .NATURAL][dat_WP, on = .NATURAL]


# COMPARISON ####
caret::RMSE(dat_pops$WorldPop_UNadj, dat_pops$IHME)
# 566840.1
caret::R2(dat_pops$WorldPop_UNadj, dat_pops$IHME, formula = "traditional")
# 0.9969525

plot(sapply(split(dat_pops, by = "year"), function(x) caret::RMSE(x$WorldPop_UNadj, x$IHME)))
plot(sapply(split(dat_pops, by = "year"), function(x) caret::R2(x$WorldPop_UNadj, x$IHME, formula = "traditional")))

caret::RMSE(dat_pops$WorldPop, dat_pops$IHME)
# 556194.3
caret::R2(dat_pops$WorldPop, dat_pops$IHME, formula = "traditional")
# 0.9970659
plot(sapply(split(dat_pops, by = "year"), function(x) caret::RMSE(x$WorldPop, x$IHME)))
plot(sapply(split(dat_pops, by = "year"), function(x) caret::R2(x$WorldPop, x$IHME, formula = "traditional")))

library(ggplot2)

# parallel plots 
ggplot(dat_pops, aes(x = year, y = IHME, col = province)) + 
  geom_point() +
  geom_line(mapping = aes(y = WorldPop), lty = "dotted") +
  geom_line(mapping = aes(y = WorldPop_UNadj), lty = "dashed")
# Papua diverges a fair bit, but mostly aligned around 2008-2009 years


# Difference compared to IHME
dat_pops_diff <- dat_pops[, .(province, year, difference_WorldPop = WorldPop-IHME, 
                              difference_WorldPop_UNadj = WorldPop_UNadj-IHME)]

ggplot(melt(dat_pops_diff, id.vars = c("province", "year"), variable.name = "difference"), 
       aes(x = year, col = province, y = value)) + 
  facet_wrap(~difference) +
  geom_linerange(mapping = aes(ymin = 0, ymax = value), position = position_dodge(width = 0.5))
  

