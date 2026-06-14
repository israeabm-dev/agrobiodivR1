#' Télécharger une image satellite Sentinel-2
#'
#' @param aoi sf ou bbox vecteur. Zone d'intérêt.
#' @param date Date de début (ex: "2023-06-01")
#' @param date_end Date de fin (par défaut = date + 1 mois)
#' @param cloud_cover Maximum de couverture nuageuse (0-100)
#' @param output_dir Dossier de sortie
#' @param ... Autres paramètres pour `CDSE::get_image`
#'
#' @return Chemin du fichier raster téléchargé (ou un SpatRaster)
#' @export
#'
#' @examples
#' \dontrun{
#' \dontrun{
#'   library(sf)
#'   aoi <- st_read("my_area.shp")
#'   download_satellite_data(aoi, "2023-06-01")
#' }
#' }
download_satellite_data <- function(aoi, date, date_end = NULL, cloud_cover = 20,
                                    output_dir = "data/satellite", ...) {

  # Vérifier les packages nécessaires
  if (!requireNamespace("CDSE", quietly = TRUE))
    stop("Le package CDSE est requis. Installez-le avec : install.packages('CDSE')")
  if (!requireNamespace("terra", quietly = TRUE))
    stop("Le package terra est requis.")

  # Créer le dossier de sortie
  if (!dir.exists(output_dir)) dir.create(output_dir, recursive = TRUE)

  # Si date_end est NULL, prendre date + 30 jours
  if (is.null(date_end)) date_end <- as.character(as.Date(date) + 30)

  # Authentification Copernicus (nécessite un compte)
  # L'utilisateur devra avoir défini les variables d'environnement CDSE_USER et CDSE_PASSWORD
  # Ou utiliser CDSE::login()

  # Télécharger l'image
  tryCatch({
    img <- CDSE::GetImage(
      aoi = aoi,
      date = date,
      date_end = date_end,
      cloud_cover = cloud_cover,
      collection = "sentinel-2-l2a",   # Niveau 2A (réflectance)
      product_type = "TOA",
      output_dir = output_dir,
      ...
    )
    message("Image téléchargée avec succès dans : ", output_dir)
    return(invisible(img))
  }, error = function(e) {
    stop("Erreur lors du téléchargement : ", e$message)
  })
}
