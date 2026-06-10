#' Importer les données de biodiversité
#'
#' Importe et prépare les données de biodiversité terrain depuis un fichier
#' CSV ou Excel. Gère les valeurs manquantes, convertit en objet spatial
#' et crée une matrice de communautés.
#'
#' @param file Chemin vers le fichier CSV ou Excel contenant les données.
#'   Si NULL, utilise le jeu de données d'exemple \code{sample_biodiversity}.
#' @param sep Séparateur pour les fichiers CSV (défaut: ",").
#' @param coords Noms des colonnes de coordonnées GPS (défaut: c("lon", "lat")).
#' @param crs Système de coordonnées de référence (défaut: 4326 = WGS84).
#'
#' @return Une liste contenant :
#' \describe{
#'   \item{community_matrix}{Matrice sites × espèces (abondances)}
#'   \item{sf_object}{Objet sf avec les points d'observation géoréférencés}
#'   \item{raw_data}{Data.frame original nettoyé}
#' }
#'
#' @importFrom sf st_as_sf st_crs
#' @importFrom dplyr mutate filter select
#' @importFrom tidyr pivot_wider
#' @importFrom readxl read_excel
#'
#' @export
#'
#' @examples
#' # Utiliser les données d'exemple
#' result <- import_biodiversity_data()
#' head(result$community_matrix)
#' print(result$sf_object)
#'
#' # Avec un fichier CSV
#' \dontrun{
#' result <- import_biodiversity_data("mes_donnees.csv")
#' }
import_biodiversity_data <- function(file = NULL, sep = ",",
                                      coords = c("lon", "lat"),
                                      crs = 4326) {

  # Chargement des données
  if (is.null(file)) {
    message("Aucun fichier fourni. Utilisation du jeu de données d'exemple.")
    data <- agrobiodivR::sample_biodiversity
  } else {
    ext <- tools::file_ext(file)
    if (ext %in% c("xlsx", "xls")) {
      data <- readxl::read_excel(file)
    } else {
      data <- utils::read.csv(file, sep = sep, stringsAsFactors = FALSE)
    }
  }

  # Vérification des colonnes obligatoires
  required_cols <- c("espece", "abondance", "parcelle")
  missing_cols <- setdiff(required_cols, names(data))
  if (length(missing_cols) > 0) {
    stop("Colonnes manquantes : ", paste(missing_cols, collapse = ", "))
  }

  # Nettoyage des NA
  n_before <- nrow(data)
  data <- data[complete.cases(data[, required_cols]), ]
  n_after <- nrow(data)
  if (n_before > n_after) {
    message(n_before - n_after, " ligne(s) avec NA supprimée(s).")
  }

  # Matrice de communautés (sites x espèces)
  community_matrix <- tapply(data$abondance, list(data$parcelle, data$espece), sum)
  community_matrix[is.na(community_matrix)] <- 0

  # Objet spatial sf (si coordonnées disponibles)
  sf_object <- NULL
  if (all(coords %in% names(data))) {
    sf_object <- sf::st_as_sf(data,
                               coords = coords,
                               crs = crs,
                               remove = FALSE)
  } else {
    warning("Colonnes de coordonnées '", paste(coords, collapse = "', '"),
            "' non trouvées. Objet sf non créé.")
  }

  return(list(
    community_matrix = community_matrix,
    sf_object        = sf_object,
    raw_data         = data
  ))
}
