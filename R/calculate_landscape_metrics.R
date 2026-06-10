#' Calculer les métriques paysagères
#'
#' Calcule des métriques paysagères simples à partir d'un raster d'occupation
#' du sol : taille des patches, fragmentation, proportion d'habitats naturels,
#' et diversité du paysage (indice de Shannon paysager).
#'
#' @param landcover Objet \code{SpatRaster} d'occupation du sol
#'   (issu de \code{import_landcover}).
#' @param zones Objet sf des zones/parcelles pour le calcul par zone.
#'   Si NULL, calcule sur l'emprise complète.
#'
#' @return Un data.frame avec les métriques paysagères :
#' \describe{
#'   \item{zone}{Identifiant de la zone (si zones fourni)}
#'   \item{n_patches}{Nombre de patches (fragments)}
#'   \item{mean_patch_size_ha}{Taille moyenne des patches en hectares}
#'   \item{prop_agriculture}{Proportion de surface agricole (0-1)}
#'   \item{prop_naturel}{Proportion d'habitats naturels (forêt + prairie) (0-1)}
#'   \item{prop_urbain}{Proportion de surfaces urbaines (0-1)}
#'   \item{shannon_paysage}{Indice de Shannon paysager (diversité des classes)}
#'   \item{fragmentation}{Indice de fragmentation (n_patches / surface_km2)}
#' }
#'
#' @importFrom terra values res freq
#'
#' @export
#'
#' @examples
#' lc <- import_landcover()
#' metrics <- calculate_landscape_metrics(lc)
#' print(metrics)
calculate_landscape_metrics <- function(landcover, zones = NULL) {

  if (!inherits(landcover, "SpatRaster")) {
    stop("landcover doit être un objet SpatRaster (package terra).")
  }

  .calc_metrics_single <- function(r) {
    freq_table <- terra::freq(r)
    freq_table <- freq_table[!is.na(freq_table$value), ]

    total_cells <- sum(freq_table$count)
    if (total_cells == 0) return(NULL)

    # Résolution en mètres (approx si WGS84)
    res_m  <- mean(terra::res(r)) * 111320  # degrés -> mètres approx
    cell_ha <- (res_m^2) / 10000

    prop <- freq_table$count / total_cells

    # Proportions par classe (codes : 1=Agri, 2=Forêt, 3=Prairie, 4=Urbain)
    get_prop <- function(code) {
      idx <- freq_table$value == code
      if (any(idx)) freq_table$count[idx] / total_cells else 0
    }

    prop_agriculture <- get_prop(1)
    prop_foret       <- get_prop(2)
    prop_prairie     <- get_prop(3)
    prop_naturel     <- prop_foret + prop_prairie
    prop_urbain      <- get_prop(4)

    # Shannon paysager
    prop_pos        <- prop[prop > 0]
    shannon_paysage <- -sum(prop_pos * log(prop_pos))

    # Fragmentation simplifiée (nombre de classes / surface)
    surface_km2  <- total_cells * cell_ha / 100
    n_patches    <- nrow(freq_table)
    fragmentation <- n_patches / max(surface_km2, 0.01)

    data.frame(
      n_patches          = n_patches,
      mean_patch_size_ha = round(total_cells * cell_ha / n_patches, 2),
      prop_agriculture   = round(prop_agriculture, 3),
      prop_naturel       = round(prop_naturel, 3),
      prop_urbain        = round(prop_urbain, 3),
      shannon_paysage    = round(shannon_paysage, 4),
      fragmentation      = round(fragmentation, 4)
    )
  }

  if (is.null(zones)) {
    result <- .calc_metrics_single(landcover)
    result$zone <- "global"
    result <- result[, c("zone", setdiff(names(result), "zone"))]
  } else {
    result_list <- lapply(seq_len(nrow(zones)), function(i) {
      cropped <- terra::crop(landcover, terra::vect(zones[i, ]))
      masked  <- terra::mask(cropped, terra::vect(zones[i, ]))
      m       <- .calc_metrics_single(masked)
      if (!is.null(m)) {
        m$zone <- as.character(i)
        m
      }
    })
    result <- do.call(rbind, Filter(Negate(is.null), result_list))
  }

  return(result)
}
