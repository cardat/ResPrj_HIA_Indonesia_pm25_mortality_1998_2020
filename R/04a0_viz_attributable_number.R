# targets::tar_workspace(fig_attributable_number)

viz_attributable_number <- function(
    data_attributable_number_alt,
    file_tidy_geography
){
  v <- vect(file_tidy_geography)
  # simplify for plotting
  v <- terra::simplifyGeom(v, 0.01)
  
  dat_attributable <- data_attributable_number_alt
  
  # total by year and province
  dat_total_an.yy <- dat_attributable[, .(attributable = sum(attributable)), by = .(country_name, province, cause, year)]
  # total overall by province
  dat_total_an <- dat_attributable[, .(attributable = sum(attributable)), by = .(country_name, province, cause)]
  
  v_total_an <- merge(v, dat_total_an)
  v_total_an.yy <- merge(v, dat_total_an.yy)
  
  
  # Output plots ####
  
  outfile1 <- "figs_and_tabs/ts_attributable_number_by_year.png"
  outfile2 <- "figs_and_tabs/map_total_attributable_number.png"
  # outfile3 <- "figs_and_tabs/map_attributable_number_by_year.png"
  outfs <- c(outfile1, outfile2)
  for (f in outfs){
    if(!dir.exists(dirname(f))) dir.create(dirname(f))
  }
  
  ## Timeseries plot (annual) ####
  ggplot(dat_total_an.yy, aes(x = year, y = attributable, col = province)) + 
    geom_line() +
    geom_line(data = dat_total_an.yy[, .(attributable = sum(attributable)), by = .(year)], col = "black") +
    scale_y_continuous(label = function(x) sprintf("%ik", x/1000))
  ggsave(outfile1, width = 10, height = 6)
  
  ## spatial plot of total ####
  png(outfile2, width = 1200, height = 800)
  plot(v_total_an, "attributable", 
       col = terra::map.pal("reds"),
       breaks = seq(0, max(v_total_an$attributable)+50000, 50000),
       plg = list(x = "bottomleft"),
       main = sprintf("Attributable number (all-causes) %04i-%04i", 
                      min(yys_todo),
                      max(yys_todo))
  )
  dev.off()
  
  ## spatial plot by year ####
  ggplot(st_as_sf(v_total_an.yy), aes(fill = attributable)) +
    geom_sf() +
    scale_fill_distiller(palette = "Reds", direction = 1,
                         label = function(x) sprintf("%ik", x/1000)) +
    facet_wrap(~year)
  # ggsave(outfile3, width = 10, height = 7)
  
  return(outfs)
}