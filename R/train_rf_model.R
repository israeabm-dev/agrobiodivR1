#' Entraîner un modèle Random Forest
#'
#' Modélise la relation entre les pratiques agricoles / métriques paysagères
#' et la biodiversité via un algorithme Random Forest.
#'
#' @param data Data.frame contenant les variables explicatives et la variable cible.
#' @param target Nom de la colonne cible (indice de biodiversité). Défaut: "shannon".
#' @param predictors Vecteur de noms de colonnes explicatives.
#'   Si NULL, utilise toutes les colonnes numériques sauf \code{target}.
#' @param ntree Nombre d'arbres. Défaut: 500.
#' @param test_split Proportion des données pour la validation (0-1). Défaut: 0.3.
#' @param seed Graine aléatoire. Défaut: 42.
#'
#' @return Une liste contenant :
#' \describe{
#'   \item{model}{Objet randomForest entraîné}
#'   \item{importance}{Data.frame d'importance des variables (\%IncMSE)}
#'   \item{train_data}{Données d'entraînement}
#'   \item{test_data}{Données de test}
#' }
#'
#' @importFrom randomForest randomForest importance
#' @importFrom stats model.matrix
#'
#' @export
#'
#' @examples
#' # Données simulées
#' set.seed(1)
#' df <- data.frame(
#'   shannon       = runif(50, 0, 2),
#'   fragmentation = runif(50),
#'   prop_naturel  = runif(50),
#'   prop_agri     = runif(50)
#' )
#' model_result <- train_rf_model(df, target = "shannon")
#' print(model_result$importance)
train_rf_model <- function(data, target = "shannon",
                            predictors = NULL,
                            ntree = 500,
                            test_split = 0.3,
                            seed = 42) {

  if (!target %in% names(data)) {
    stop("Variable cible '", target, "' absente du data.frame.")
  }

  # Sélection des prédicteurs
  if (is.null(predictors)) {
    num_cols    <- names(data)[sapply(data, is.numeric)]
    predictors  <- setdiff(num_cols, target)
  }
  missing_pred <- setdiff(predictors, names(data))
  if (length(missing_pred) > 0) {
    stop("Prédicteurs manquants : ", paste(missing_pred, collapse = ", "))
  }

  model_data <- data[, c(target, predictors)]
  model_data <- model_data[complete.cases(model_data), ]

  if (nrow(model_data) < 10) {
    stop("Trop peu d'observations complètes (", nrow(model_data), "). Minimum : 10.")
  }

  # Split train / test
  set.seed(seed)
  n_test      <- floor(nrow(model_data) * test_split)
  test_idx    <- sample(seq_len(nrow(model_data)), n_test)
  train_data  <- model_data[-test_idx, ]
  test_data   <- model_data[test_idx,  ]

  message("Entraînement Random Forest : ", nrow(train_data), " obs. | ",
          "Test : ", nrow(test_data), " obs. | ",
          length(predictors), " prédicteur(s).")

  # Formule
  formula_rf <- stats::as.formula(paste(target, "~", paste(predictors, collapse = " + ")))

  # Modèle
  rf_model <- randomForest::randomForest(
    formula  = formula_rf,
    data     = train_data,
    ntree    = ntree,
    importance = TRUE
  )

  # Importance des variables
  imp_mat <- randomForest::importance(rf_model, type = 1)  # %IncMSE
  imp_df  <- data.frame(
    variable   = rownames(imp_mat),
    pct_inc_mse = round(imp_mat[, 1], 4),
    row.names  = NULL
  )
  imp_df <- imp_df[order(imp_df$pct_inc_mse, decreasing = TRUE), ]

  message("Modèle entraîné. Variable la plus importante : ", imp_df$variable[1])

  return(list(
    model      = rf_model,
    importance = imp_df,
    train_data = train_data,
    test_data  = test_data
  ))
}
