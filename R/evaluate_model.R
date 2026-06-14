#' Évaluer les performances d'un modèle Random Forest
#'
#' Calcule RMSE, R² et produit un graphique des valeurs observées vs prédites.
#'
#' @param rf_result Liste retournée par \code{\link{train_rf_model}}.
#'   Doit contenir les éléments \code{model} et \code{test_data}.
#' @param target Nom de la variable cible (par défaut "shannon").
#'   Doit correspondre à celui utilisé dans \code{train_rf_model}.
#'
#' @return Une liste contenant :
#'   \item{RMSE}{Root Mean Square Error}
#'   \item{R2}{Coefficient de détermination}
#'   \item{plot}{Graphique ggplot2 observed vs predicted}
#'   \item{predictions}{Data.frame avec les valeurs observées et prédites}
#'
#' @importFrom stats predict cor complete.cases
#' @importFrom ggplot2 ggplot aes geom_point geom_abline labs theme_minimal
#' @importFrom stats predict
#' @export
#'
#' @examples
#' \dontrun{
#' \dontrun{
#'   result <- train_rf_model(biodiv_data, target = "shannon")
#'   evaluation <- evaluate_model(result)
#'   print(evaluation$RMSE)
#'   print(evaluation$plot)
#' }
#' }
evaluate_model <- function(rf_result, target = "shannon") {
  Observed <- Predicted <- NULL
  # Vérifications
  if (!"model" %in% names(rf_result) || !"test_data" %in% names(rf_result)) {
    stop("rf_result doit être une liste retournée par train_rf_model() contenant 'model' et 'test_data'")
  }
  if (!target %in% names(rf_result$test_data)) {
    stop("La variable cible '", target, "' n'existe pas dans test_data")
  }

  # Prédictions sur le jeu de test
  predictions <- stats::predict(rf_result$model, newdata = rf_result$test_data)
  observed <- rf_result$test_data[[target]]

  # Calcul des métriques
  rmse <- sqrt(mean((observed - predictions)^2, na.rm = TRUE))
  r2 <- cor(observed, predictions, use = "complete.obs")^2

  # Graphique
  df_plot <- data.frame(Observed = observed, Predicted = predictions)
  p <- ggplot2::ggplot(df_plot, ggplot2::aes(x = Observed, y = Predicted)) +
    ggplot2::geom_point(alpha = 0.6, color = "steelblue") +
    ggplot2::geom_abline(slope = 1, intercept = 0, color = "red", linetype = "dashed", linewidth = 1) +
    ggplot2::labs(
      title = "Prédictions vs Observations (Random Forest)",
      subtitle = paste0("R² = ", round(r2, 3), " | RMSE = ", round(rmse, 3)),
      x = "Valeurs observées", y = "Valeurs prédites"
    ) +
    ggplot2::theme_minimal()

  # Retour
  return(list(
    RMSE = rmse,
    R2 = r2,
    plot = p,
    predictions = data.frame(observed = observed, predicted = predictions)
  ))
}
