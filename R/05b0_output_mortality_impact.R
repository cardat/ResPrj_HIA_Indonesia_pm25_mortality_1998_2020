output_mortality_impact <- function(
    data_mortality_impact,
    outdir = "data_derived") {
  
  
  # Save
  if(!dir.exists(outdir)) dir.create(outdir, recursive = T)
  
  outf <- file.path(outdir, 
                    sprintf("mortality_impact_%s.csv", runDate()))
  fwrite(data_mortality_impact, outf)
  
  return(outf)
}
