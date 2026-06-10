#' Analyser la connectivité écologique
#'
#' Analyse la connectivité entre patches d'habitats naturels en calculant
#' les distances inter-patches, identifiant les zones isolées et proposant
#' des corridors écologiques potentiels.
#'
#' @param landcover Objet \code{SpatRaster} d'occupation du sol.
#' @param habitat_codes Codes des habitats naturels. Défaut: c(2, 3).
#' @param max_distance_m Seuil de distance (en mètres) au-delà duquel
#'   un patch est considéré isolé. Défaut: 500.
#'
#' @return Une liste contenant :
#' \describe{
#'   \item{connectivity_index}{Indice global de connectivité (0-1)}
#'   \item{isolated_zones}{SpatRaster des zones isolées}
#'   \item{corridor_raster}{SpatRaster des corridors potentiels (zones < seuil)}
#'   \item{summary}{Data.frame de résumé}
#' }
#'
#' @importFrom terra distance values ifel classify
#'
#' @export
#'
#' @examples
#' lc <- import_landcover()
#' conn <- analyze_connectivity(lc, max_distance_m = 300)
#' print(conn$summary)
#' terra::plot(conn$corridor_raster, main = "Corridors potentiels")
analyze_connectivity <- function(landcover, habitat_codes = c(2, 3),
                                  max_distance_m = 500) {

  if (!inherits(landcover, "SpatRaster")) {
    stop("landcover doit être un SpatRaster.")
  }

  # Masque habitats
  vals      <- terra::values(landcover)
  hab_vals  <- ifelse(vals %in% habitat_codes, 1, NA)
  hab_mask  <- landcover
  terra::values(hab_mask) <- hab_vals

  # Raster de distance aux habitats
  message("Calcul de la connectivité (seuil : ", max_distance_m, " m)...")
  dist_r <- terra::distance(hab_mask)

  # Corridors potentiels : zones non-habitat à moins de max_distance_m
  non_habitat <- is.na(hab_vals)
  corridor_vals <- ifelse(non_habitat & terra::values(dist_r) <= max_distance_m,
                          1, NA)
  corridor_r <- dist_r
  terra::values(corridor_r) <- corridor_vals
  names(corridor_r) <- "corridor_potentiel"

  # Zones isolées : non-habitat ET distance > seuil
  isolated_vals <- ifelse(non_habitat & terra::values(dist_r) > max_distance_m,
                          1, NA)
  isolated_r <- dist_r
  terra::values(isolated_r) <- isolated_vals
  names(isolated_r) <- "zone_isolee"

  # Indice de connectivité = proportion de l'espace non-habitat < seuil
  n_non_hab   <- sum(non_habitat, na.rm = TRUE)
  n_corridor  <- sum(!is.na(corridor_vals), na.rm = TRUE)
  conn_index  <- if (n_non_hab > 0) round(n_corridor / n_non_hab, 4) else 0

  summary_df <- data.frame(
    seuil_m            = max_distance_m,
    n_cells_habitat    = sum(!is.na(hab_vals), na.rm = TRUE),
    n_cells_corridor   = n_corridor,
    n_cells_isoles     = sum(!is.na(isolated_vals), na.rm = TRUE),
    connectivity_index = conn_index
  )

  message("Indice de connectivité : ", conn_index,
          " (", round(conn_index * 100, 1), "% de l'espace non-habitat connecté)")

  return(list(
    connectivity_index = conn_index,
    isolated_zones     = isolated_r,
    corridor_raster    = corridor_r,
    summary            = summary_df
  ))
}
