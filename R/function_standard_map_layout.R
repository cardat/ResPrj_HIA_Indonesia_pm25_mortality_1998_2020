standard_map_layout <- function(tmap_obj,
                                credit_text = NULL){
  return(
    tmap_obj + 
      tm_graticules(col = "grey80") +
      tm_scalebar() +
      tm_credits(credit_text, position = c("right", "top"))
  )
}