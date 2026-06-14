#' Analyser la connectivite ecologique
#'
#' Analyse la connectivite entre patches d'habitats naturels en calculant
#' les distances inter-patches, identifiant les zones isolees et proposant
#' des corridors ecologiques potentiels.
#'
#' @param landcover Objet \code{SpatRaster} d'occupation du sol.
#' @param habitat_codes Codes des habitats naturels. Defaut: c(2, 3).
#' @param max_distance_m Seuil de distance (en metres) au-dela duquel
#'   un patch est considere isole. Defaut: 500.
#'
#' @return Une liste contenant :
#' \describe{
#'   \item{connectivity_index}{Indice global de connectivite (0-1)}
#'   \item{isolated_zones}{SpatRaster des zones isolees}
#'   \item{corridor_raster}{SpatRaster des corridors potentiels}
#'   \item{summary}{Data.frame de resume}
#' }
#'
#' @importFrom terra distance values
#'
#' @export
#'
#' @examples
#' \dontrun{
#' \dontrun{
#' lc <- import_landcover()
#' conn <- analyze_connectivity(lc, max_distance_m = 300)
#' print(conn$summary)
#' terra::plot(conn$corridor_raster, main = "Corridors potentiels")
#' }
#' }
analyze_connectivity <- function(landcover, habitat_codes = c(2, 3),
                                 max_distance_m = 500) {
  if (!inherits(landcover, "SpatRaster")) {
    stop("landcover doit etre un SpatRaster.")
  }

  vals     <- as.vector(terra::values(landcover))
  hab_vals <- ifelse(vals %in% habitat_codes, 1, NA)

  if (all(is.na(hab_vals))) {
    warning("Aucune cellule habitat trouvee avec les codes : ",
            paste(habitat_codes, collapse = ", "),
            ". Utilisation de tous les codes presents.")
    unique_vals  <- unique(vals[!is.na(vals)])
    habitat_codes <- unique_vals[1:min(2, length(unique_vals))]
    hab_vals     <- ifelse(vals %in% habitat_codes, 1, NA)
  }

  if (all(is.na(hab_vals))) {
    stop("Impossible de trouver des cellules habitat dans le raster fourni.")
  }

  hab_mask <- landcover
  terra::values(hab_mask) <- hab_vals

  message("Calcul de la connectivite (seuil : ", max_distance_m, " m)...")
  dist_r    <- terra::distance(hab_mask)
  dist_vals <- as.vector(terra::values(dist_r))

  non_habitat   <- is.na(hab_vals)
  corridor_vals <- ifelse(non_habitat & dist_vals <= max_distance_m, 1, NA)
  isolated_vals <- ifelse(non_habitat & dist_vals > max_distance_m, 1, NA)

  corridor_r <- dist_r
  terra::values(corridor_r) <- corridor_vals
  names(corridor_r) <- "corridor_potentiel"

  isolated_r <- dist_r
  terra::values(isolated_r) <- isolated_vals
  names(isolated_r) <- "zone_isolee"

  n_non_hab  <- sum(non_habitat, na.rm = TRUE)
  n_corridor <- sum(!is.na(corridor_vals), na.rm = TRUE)
  conn_index <- if (n_non_hab > 0) round(n_corridor / n_non_hab, 4) else 0

  summary_df <- data.frame(
    seuil_m            = max_distance_m,
    n_cells_habitat    = sum(!is.na(hab_vals), na.rm = TRUE),
    n_cells_corridor   = n_corridor,
    n_cells_isoles     = sum(!is.na(isolated_vals), na.rm = TRUE),
    connectivity_index = conn_index
  )

  message("Indice de connectivite : ", conn_index,
          " (", round(conn_index * 100, 1),
          "% de l'espace non-habitat connecte)")

  return(list(
    connectivity_index = conn_index,
    isolated_zones     = isolated_r,
    corridor_raster    = corridor_r,
    summary            = summary_df
  ))
}
