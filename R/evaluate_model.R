#' Évaluer les performances du modèle
#'
#' Calcule les métriques de performance (RMSE, R²) et produit des
#' visualisations du modèle Random Forest.
#'
#' @param model_result Liste retournée par \code{train_rf_model}.
#' @param target Nom de la variable cible. Défaut: "shannon".
#' @param plot Logique. Si TRUE, affiche les graphiques. Défaut: TRUE.
#'
#' @return Un data.frame avec les métriques :
#' \describe{
#'   \item{set}{Jeu de données (train / test)}
#'   \item{rmse}{Erreur quadratique moyenne}
#'   \item{mae}{Erreur absolue moyenne}
#'   \item{r2}{Coefficient de détermination R²}
#' }
#'
#' @importFrom stats predict cor
#' @importFrom ggplot2 ggplot aes geom_point geom_abline geom_bar labs theme_minimal coord_flip
#'
#' @export
#'
#' @examples
#' set.seed(1)
#' df <- data.frame(
#'   shannon       = runif(50, 0, 2),
#'   fragmentation = runif(50),
#'   prop_naturel  = runif(50)
#' )
#' model_result <- train_rf_model(df, target = "shannon")
#' perf <- evaluate_model(model_result, target = "shannon", plot = FALSE)
#' print(perf)
evaluate_model <- function(model_result, target = "shannon", plot = TRUE) {

  if (!all(c("model", "train_data", "test_data") %in% names(model_result))) {
    stop("model_result doit être la liste retournée par train_rf_model().")
  }

  rf       <- model_result$model
  train_df <- model_result$train_data
  test_df  <- model_result$test_data

  .metrics <- function(actual, predicted, set_name) {
    rmse <- sqrt(mean((actual - predicted)^2))
    mae  <- mean(abs(actual - predicted))
    ss_res <- sum((actual - predicted)^2)
    ss_tot <- sum((actual - mean(actual))^2)
    r2   <- 1 - ss_res / ss_tot
    data.frame(set = set_name,
               rmse = round(rmse, 4),
               mae  = round(mae, 4),
               r2   = round(r2, 4))
  }

  pred_train <- stats::predict(rf, newdata = train_df)
  pred_test  <- stats::predict(rf, newdata = test_df)

  perf <- rbind(
    .metrics(train_df[[target]], pred_train, "train"),
    .metrics(test_df[[target]],  pred_test,  "test")
  )

  message("=== Performances ===")
  print(perf)

  if (plot) {
    # Observed vs Predicted (test)
    plot_data <- data.frame(
      observed  = test_df[[target]],
      predicted = pred_test
    )
    p1 <- ggplot2::ggplot(plot_data, ggplot2::aes(x = observed, y = predicted)) +
      ggplot2::geom_point(alpha = 0.7, color = "steelblue", size = 2) +
      ggplot2::geom_abline(slope = 1, intercept = 0, color = "red", linetype = 2) +
      ggplot2::labs(title = "Observé vs Prédit (jeu test)",
                    x = paste("Observé :", target),
                    y = paste("Prédit :", target),
                    subtitle = paste0("R² = ", perf$r2[perf$set == "test"],
                                      "  |  RMSE = ", perf$rmse[perf$set == "test"])) +
      ggplot2::theme_minimal()

    # Importance des variables
    imp_df <- model_result$importance
    p2 <- ggplot2::ggplot(imp_df,
                           ggplot2::aes(x = reorder(variable, pct_inc_mse),
                                        y = pct_inc_mse,
                                        fill = pct_inc_mse)) +
      ggplot2::geom_bar(stat = "identity") +
      ggplot2::coord_flip() +
      ggplot2::labs(title = "Importance des variables (%IncMSE)",
                    x = "Variable", y = "%IncMSE") +
      ggplot2::theme_minimal() +
      ggplot2::theme(legend.position = "none")

    print(p1)
    print(p2)
  }

  return(perf)
}
