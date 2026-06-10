#' Importer les données d'occupation du sol
#'
#' Importe et prépare un raster d'occupation du sol (Corine Land Cover,
#' ESA Land Cover, ou fichier local). Effectue la reclassification et le
#' découpage sur la zone d'étude.
#'
#' @param file Chemin vers un fichier raster (GeoTIFF, .img, etc.).
#'   Si NULL, utilise le raster d'exemple \code{sample_landcover}.
#' @param study_area Objet sf définissant la zone d'étude pour le découpage.
#'   Si NULL, utilise l'emprise complète du raster.
#' @param reclassify Logique. Si TRUE, reclassifie les codes CLC en
#'   grandes catégories (Agriculture, Forêt, Prairie, Urbain, Eau, Autre).
#'   Défaut: TRUE.
#' @param crs_target EPSG cible pour la reprojection. Défaut: 4326.
#'
#' @return Un objet \code{SpatRaster} (terra) avec les classes d'occupation du sol.
#'
#' @importFrom terra rast project crop mask values
#' @importFrom sf st_transform st_crs
#'
#' @export
#'
#' @examples
#' lc <- import_landcover()
#' terra::plot(lc, main = "Occupation du sol")
#'
#' \dontrun{
#' # Avec un fichier CLC local
#' lc <- import_landcover("CLC2018_MA.tif", reclassify = TRUE)
#' }
import_landcover <- function(file = NULL, study_area = NULL,
                              reclassify = TRUE, crs_target = 4326) {

  # Chargement du raster
  if (is.null(file)) {
    message("Utilisation du raster d'occupation du sol d'exemple.")
    lc_raster <- agrobiodivR::sample_landcover
  } else {
    if (!file.exists(file)) stop("Fichier introuvable : ", file)
    lc_raster <- terra::rast(file)
    message("Raster chargé : ", file,
            " | Dimensions : ", terra::nrow(lc_raster), "x", terra::ncol(lc_raster))
  }

  # Reprojection si nécessaire
  if (!is.null(crs_target)) {
    target_crs <- paste0("EPSG:", crs_target)
    if (terra::crs(lc_raster, describe = TRUE)$code != as.character(crs_target)) {
      lc_raster <- terra::project(lc_raster, target_crs, method = "near")
      message("Raster reprojeté en EPSG:", crs_target)
    }
  }

  # Découpage sur la zone d'étude
  if (!is.null(study_area)) {
    study_area <- sf::st_transform(study_area, terra::crs(lc_raster))
    lc_raster  <- terra::crop(lc_raster, study_area)
    lc_raster  <- terra::mask(lc_raster, terra::vect(study_area))
    message("Raster découpé sur la zone d'étude.")
  }

  # Reclassification CLC -> grandes catégories
  if (reclassify) {
    lc_raster <- .reclassify_clc(lc_raster)
    message("Reclassification effectuée : Agriculture(1), Forêt(2), ",
            "Prairie(3), Urbain(4), Eau(5), Autre(6)")
  }

  return(lc_raster)
}

# Fonction interne de reclassification CLC
.reclassify_clc <- function(r) {
  vals <- terra::values(r)
  new_vals <- dplyr::case_when(
    vals %in% 11:22   ~ 1L,  # Agriculture
    vals %in% 31:33   ~ 2L,  # Forêt
    vals == 23        ~ 3L,  # Prairie
    vals %in% 1:11    ~ 4L,  # Urbain
    vals %in% 40:44   ~ 5L,  # Eau
    TRUE              ~ 6L   # Autre
  )
  terra::values(r) <- new_vals
  levels(r) <- data.frame(
    id    = 1:6,
    label = c("Agriculture", "Forêt", "Prairie", "Urbain", "Eau", "Autre")
  )
  return(r)
}
