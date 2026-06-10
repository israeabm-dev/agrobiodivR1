#' Calculer les indices de biodiversité
#'
#' Calcule les principaux indices de biodiversité (Shannon, Simpson, richesse
#' spécifique) par parcelle/site à partir d'une matrice de communautés.
#'
#' @param community_matrix Matrice sites × espèces (issue de \code{import_biodiversity_data}).
#'   Peut aussi être un data.frame avec colonnes espece, abondance, parcelle.
#'
#' @return Un data.frame avec les colonnes :
#' \describe{
#'   \item{parcelle}{Identifiant du site}
#'   \item{richesse}{Nombre d'espèces observées}
#'   \item{shannon}{Indice de Shannon (H')}
#'   \item{simpson}{Indice de Simpson (D)}
#'   \item{evenness}{Équitabilité de Pielou (J')}
#'   \item{abondance_totale}{Nombre total d'individus}
#' }
#'
#' @importFrom vegan diversity specnumber
#'
#' @export
#'
#' @examples
#' result <- import_biodiversity_data()
#' indices <- calculate_diversity_indices(result$community_matrix)
#' print(indices)
#'
#' # Visualisation rapide
#' \dontrun{
#' barplot(indices$shannon, names.arg = indices$parcelle,
#'         main = "Indice de Shannon par parcelle",
#'         ylab = "H'", col = "steelblue")
#' }
calculate_diversity_indices <- function(community_matrix) {

  # Accepter un data.frame brut
  if (is.data.frame(community_matrix) &&
      all(c("espece", "abondance", "parcelle") %in% names(community_matrix))) {
    community_matrix <- tapply(community_matrix$abondance,
                                list(community_matrix$parcelle,
                                     community_matrix$espece), sum)
    community_matrix[is.na(community_matrix)] <- 0
  }

  if (!is.matrix(community_matrix) && !is.array(community_matrix)) {
    stop("community_matrix doit être une matrice ou un tableau sites x espèces.")
  }

  # Calcul des indices via vegan
  shannon <- vegan::diversity(community_matrix, index = "shannon")
  simpson <- vegan::diversity(community_matrix, index = "simpson")
  richesse <- vegan::specnumber(community_matrix)
  abondance_totale <- rowSums(community_matrix)

  # Équitabilité de Pielou : J' = H' / ln(S)
  evenness <- ifelse(richesse > 1, shannon / log(richesse), 0)

  result <- data.frame(
    parcelle         = rownames(community_matrix),
    richesse         = richesse,
    shannon          = round(shannon, 4),
    simpson          = round(simpson, 4),
    evenness         = round(evenness, 4),
    abondance_totale = abondance_totale,
    row.names        = NULL,
    stringsAsFactors = FALSE
  )

  message("Indices calculés pour ", nrow(result), " parcelle(s).")
  message("Shannon moyen : ", round(mean(result$shannon), 3),
          " | Richesse moyenne : ", round(mean(result$richesse), 1))

  return(result)
}
