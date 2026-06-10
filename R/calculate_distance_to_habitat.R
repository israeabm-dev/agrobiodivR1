#' Calculer les distances aux habitats naturels
#'
#' Calcule des rasters de distance euclidienne aux habitats d'intérêt
#' (forêt, haies, habitats semi-naturels) et extrait ces distances
#' pour chaque parcelle d'observation.
#'
#' @param landcover Objet \code{SpatRaster} d'occupation du sol.
#' @param points Objet sf avec les points d'observation (parcelles).
#'   Si NULL, retourne uniquement les rasters de distance.
#' @param habitat_codes Vecteur des codes de classes d'habitat cibles.
#'   Défaut: c(2, 3) = Forêt + Prairie.
#'
#' @return Une liste contenant :
#' \describe{
#'   \item{distance_raster}{SpatRaster de distance (en mètres approx.) aux habitats}
#'   \item{points_with_distance}{Objet sf des points avec colonne dist_habitat ajoutée}
#' }
#'
#' @importFrom terra distance values ifel extract
#' @importFrom sf st_as_sf
#'
#' @export
#'
#' @examples
#' lc <- import_landcover()
#' bd <- import_biodiversity_data()
#' result <- calculate_distance_to_habitat(lc, bd$sf_object)
#' terra::plot(result$distance_raster, main = "Distance aux habitats naturels")
calculate_distance_to_habitat <- function(landcover, points = NULL,
                                           habitat_codes = c(2, 3)) {

  if (!inherits(landcover, "SpatRaster")) {
    stop("landcover doit être un SpatRaster.")
  }

  # Masque binaire : 1 = habitat cible, NA = reste
  habitat_mask <- landcover
  vals <- terra::values(landcover)
  new_vals <- ifelse(vals %in% habitat_codes, 1, NA)
  terra::values(habitat_mask) <- new_vals

  # Raster de distance
  message("Calcul du raster de distance aux habitats (codes : ",
          paste(habitat_codes, collapse = ", "), ")...")
  dist_raster <- terra::distance(habitat_mask)
  names(dist_raster) <- "dist_habitat_m"

  # Extraction pour les points
  points_out <- NULL
  if (!is.null(points)) {
    if (!inherits(points, "sf")) stop("points doit être un objet sf.")
    pts_vect <- terra::vect(points)
    extracted <- terra::extract(dist_raster, pts_vect)
    points$dist_habitat_m <- round(extracted[, 2], 1)
    points_out <- points
    message("Distances extraites pour ", nrow(points), " point(s).")
  }

  return(list(
    distance_raster      = dist_raster,
    points_with_distance = points_out
  ))
}
