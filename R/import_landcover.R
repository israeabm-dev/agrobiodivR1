#' Importer les donnees d'occupation du sol
#'
#' Importe et prepare un raster d'occupation du sol (Corine Land Cover,
#' ESA Land Cover, ou fichier local). Effectue la reclassification et le
#' decoupage sur la zone d'etude.
#'
#' @param file Chemin vers un fichier raster (GeoTIFF, .img, etc.).
#'   Si NULL, utilise le raster d'exemple simule.
#' @param study_area Objet sf definissant la zone d'etude pour le decoupage.
#'   Si NULL, utilise l'emprise complete du raster.
#' @param reclassify Logique. Si TRUE, reclassifie les codes CLC en
#'   grandes categories (Agriculture, Foret, Prairie, Urbain, Eau, Autre).
#'   Defaut: TRUE.
#' @param crs_target EPSG cible pour la reprojection. Defaut: 4326.
#'
#' @return Un objet \code{SpatRaster} (terra) avec les classes d'occupation du sol.
#'
#' @importFrom terra rast project crop mask values ncell crs vect
#' @importFrom sf st_transform
#'
#' @export
#'
#' @examples
#' \dontrun{
#' lc <- import_landcover()
#' terra::plot(lc, main = "Occupation du sol")
#'
#' \dontrun{
#' lc <- import_landcover("CLC2018_MA.tif", reclassify = TRUE)
#' }
#' }
import_landcover <- function(file = NULL, study_area = NULL,
                             reclassify = TRUE, crs_target = 4326) {
  if (is.null(file)) {
    message("Utilisation du raster d'occupation du sol d'exemple.")
    lc_raster <- terra::rast(
      nrows = 20, ncols = 20,
      xmin = -5.5, xmax = -1.0,
      ymin = 33.0, ymax = 36.0,
      crs = "EPSG:4326"
    )
    set.seed(42)
    terra::values(lc_raster) <- sample(1:5, terra::ncell(lc_raster),
                                       replace = TRUE,
                                       prob = c(0.5, 0.2, 0.15, 0.1, 0.05))
    names(lc_raster) <- "landcover"
  } else {
    if (!file.exists(file)) stop("Fichier introuvable : ", file)
    lc_raster <- terra::rast(file)
    message("Raster charge : ", file,
            " | Dimensions : ", terra::nrow(lc_raster), "x", terra::ncol(lc_raster))
  }

  if (!is.null(crs_target)) {
    target_crs <- paste0("EPSG:", crs_target)
    if (terra::crs(lc_raster, describe = TRUE)$code != as.character(crs_target)) {
      lc_raster <- terra::project(lc_raster, target_crs, method = "near")
      message("Raster reprojete en EPSG:", crs_target)
    }
  }

  if (!is.null(study_area)) {
    study_area <- sf::st_transform(study_area, terra::crs(lc_raster))
    lc_raster  <- terra::crop(lc_raster, study_area)
    lc_raster  <- terra::mask(lc_raster, terra::vect(study_area))
    message("Raster decoupe sur la zone d'etude.")
  }

  if (reclassify) {
    lc_raster <- .reclassify_clc(lc_raster)
    message("Reclassification effectuee : Agriculture(1), Foret(2), ",
            "Prairie(3), Urbain(4), Eau(5), Autre(6)")
  }

  return(lc_raster)
}

.reclassify_clc <- function(r) {
  vals <- as.vector(terra::values(r))
  new_vals <- dplyr::case_when(
    vals %in% 11:22 ~ 1L,
    vals %in% 31:33 ~ 2L,
    vals == 23      ~ 3L,
    vals %in% 1:11  ~ 4L,
    vals %in% 40:44 ~ 5L,
    TRUE            ~ 6L
  )
  terra::values(r) <- new_vals
  levels(r) <- data.frame(
    id    = 1:6,
    label = c("Agriculture", "Foret", "Prairie", "Urbain", "Eau", "Autre")
  )
  return(r)
}
