#' Classifier les paysages agricoles par clustering
#'
#' Applique un algorithme K-means pour regrouper les zones/parcelles en
#' types de paysages homogènes selon leurs métriques paysagères.
#'
#' @param landscape_metrics Data.frame de métriques paysagères
#'   (issu de \code{calculate_landscape_metrics}).
#' @param n_clusters Nombre de clusters souhaités. Défaut: 3.
#' @param variables Variables à utiliser pour le clustering.
#'   Défaut: c("fragmentation", "shannon_paysage", "prop_naturel").
#' @param seed Graine aléatoire pour la reproductibilité. Défaut: 42.
#'
#' @return Le data.frame d'entrée enrichi d'une colonne \code{cluster}
#'   (entier de 1 à n_clusters) et d'une colonne \code{cluster_label}.
#'
#' @importFrom stats kmeans scale
#'
#' @export
#'
#' @examples
#' lc <- import_landcover()
#' metrics <- calculate_landscape_metrics(lc)
#' # Dupliquer pour avoir assez de lignes pour le clustering
#' metrics_multi <- metrics[rep(1, 10), ]
#' metrics_multi$fragmentation <- runif(10)
#' result <- cluster_landscapes(metrics_multi, n_clusters = 2)
#' print(result[, c("zone", "cluster", "cluster_label")])
cluster_landscapes <- function(landscape_metrics,
                                n_clusters = 3,
                                variables  = c("fragmentation",
                                               "shannon_paysage",
                                               "prop_naturel"),
                                seed = 42) {

  available_vars <- intersect(variables, names(landscape_metrics))
  if (length(available_vars) < 2) {
    stop("Au moins 2 variables doivent être disponibles dans landscape_metrics. ",
         "Variables demandées : ", paste(variables, collapse = ", "))
  }
  if (length(available_vars) < length(variables)) {
    warning("Variables absentes ignorées : ",
            paste(setdiff(variables, available_vars), collapse = ", "))
  }

  if (nrow(landscape_metrics) < n_clusters) {
    stop("Nombre de zones (", nrow(landscape_metrics),
         ") inférieur au nombre de clusters (", n_clusters, ").")
  }

  # Normalisation
  data_scaled <- scale(landscape_metrics[, available_vars])

  # K-means
  set.seed(seed)
  km <- stats::kmeans(data_scaled, centers = n_clusters, nstart = 25)

  landscape_metrics$cluster <- km$cluster

  # Labels descriptifs basés sur la fragmentation et la naturalité
  centers_df <- as.data.frame(km$centers)
  label_map  <- character(n_clusters)
  for (k in 1:n_clusters) {
    frag    <- if ("fragmentation"  %in% names(centers_df)) centers_df$fragmentation[k]  else 0
    nat     <- if ("prop_naturel"   %in% names(centers_df)) centers_df$prop_naturel[k]   else 0
    shannon <- if ("shannon_paysage" %in% names(centers_df)) centers_df$shannon_paysage[k] else 0
    label_map[k] <- dplyr::case_when(
      nat > 0.5                    ~ paste0("Cluster ", k, " : Paysage naturel"),
      frag > 0.5                   ~ paste0("Cluster ", k, " : Paysage fragmenté"),
      shannon > mean(centers_df$shannon_paysage %||% 0) ~ paste0("Cluster ", k, " : Paysage diversifié"),
      TRUE                         ~ paste0("Cluster ", k, " : Paysage agricole")
    )
  }

  landscape_metrics$cluster_label <- label_map[landscape_metrics$cluster]

  message("K-means terminé. Répartition des clusters :")
  print(table(landscape_metrics$cluster_label))

  attr(landscape_metrics, "kmeans_model") <- km
  return(landscape_metrics)
}

# Opérateur null-coalesce interne
`%||%` <- function(a, b) if (!is.null(a)) a else b
