#' Calcul de métriques paysagères simples
#'
#'@importFrom landscapemetrics calculate_lsm
#' @param landcover_raster SpatRaster ou RasterLayer. Carte d'occupation du sol.
#' @param zone sf (optionnel). Zones pour lesquelles calculer les métriques.
#'
#' @return Un data.frame au format long contenant les métriques calculées par classe et au niveau paysager. Un attribut `fragmentation_index` est ajouté.
#' @export
#'
#' @examples
#' \dontrun{
#' \dontrun{
#'   r <- terra::rast("landcover.tif")
#'   metrics <- calculate_landscape_metrics(r)
#'   print(metrics)
#'   attr(metrics, "fragmentation_index")
#' }
#' }
calculate_landscape_metrics <- function(landcover_raster, zone = NULL) {
  if (!requireNamespace("landscapemetrics", quietly = TRUE))
    stop("Installez landscapemetrics avec : install.packages('landscapemetrics')")
  if (!requireNamespace("terra", quietly = TRUE))
    stop("Package terra requis")

  # Découpage si une zone est fournie
  if (!is.null(zone)) {
    landcover_raster <- terra::crop(landcover_raster, terra::vect(zone))
    landcover_raster <- terra::mask(landcover_raster, terra::vect(zone))
  }

  # Métriques au niveau classe et paysage
  metrics <- landscapemetrics::calculate_lsm(landcover_raster,
                                             what = c("lsm_c_np",       # nombre de patches par classe
                                                      "lsm_c_area_mn",   # taille moyenne des patches par classe
                                                      "lsm_c_pland",     # proportion de chaque classe
                                                      "lsm_c_ai",        # indice d'agrégation par classe
                                                      "lsm_l_ta",        # surface totale paysage
                                                      "lsm_l_ed",        # densité de bordure paysage
                                                      "lsm_l_pr"),       # nombre de patches total
                                             verbose = FALSE)

  # Calcul d'un indice de fragmentation global (basé sur l'AI moyen des classes)
  ai_vals <- metrics[metrics$metric == "ai", "value"]
  if (length(ai_vals) > 0) {
    mean_ai <- mean(ai_vals, na.rm = TRUE)
    frag_index <- 1 - (mean_ai / 100)
    attr(metrics, "fragmentation_index") <- frag_index
    message("Indice de fragmentation global = ", round(frag_index, 3))
  } else {
    warning("Métrique 'ai' non trouvée, pas d'indice de fragmentation.")
    attr(metrics, "fragmentation_index") <- NA
  }

  return(metrics)
}
