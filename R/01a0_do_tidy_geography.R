#' do_tidy_geography
#'
#' Subset raw vector file to required geography and level (national or provincial), clean the field headings and output to file.
#' 
#' @param file_geography File path to vector file of country/state/province boundaries (e.g. shapefile)
#' @param outfile File path for cleaned vector data output
#'
#' @returns character - File path of output (vector file with national and state/province-level codes and/or names)

do_tidy_geography <- function(file_geography, outfile){
  # select country
  country_code <- c("IDN")
  
  # read and subset by SQL-like query
  v <- vect(file_geography,
            query = sprintf("SELECT geom, 
                                ID_0, 
                                COUNTRY, 
                                NAME_1
                            FROM level1 
                            WHERE ID_0 IN ('%s')", 
                            paste(country_code, collapse = "', '"))
  )
  
  # rename for ease of use in downstream targets
  names(v) <- c("country_code", "country_name", "province")
  
  # output
  if(!dir.exists(dirname(outfile))) dir.create(dirname(outfile))
  writeVector(v, outfile, overwrite = TRUE)
  return(outfile)
}
