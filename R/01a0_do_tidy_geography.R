# targets::tar_workspace(file_tidy_geography)

do_tidy_geography <- function(file_geography, outfile){
  # Subset to required geography and level (national or provincial)
  country_code <- c("IDN")
  
  v <- vect(file_geography,
            query = sprintf("SELECT geom, 
                                ID_0, 
                                COUNTRY, 
                                NAME_1
                            FROM level1 
                            WHERE ID_0 IN ('%s')", 
                            paste(country_code, collapse = "', '"))
  )
  
  # rename for ease of use
  names(v) <- c("country_code", "country_name", "province")
  
  if(!dir.exists(dirname(outfile))) dir.create(dirname(outfile))
  writeVector(v, outfile, overwrite = TRUE)
  return(outfile)
}
