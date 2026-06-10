## Tests unitaires pour agrobiodivR
## Exécuter avec : devtools::test() ou testthat::test_file("tests/testthat/test-diversity.R")

library(testthat)

# ---- Tests : import_biodiversity_data ----
test_that("import_biodiversity_data retourne une liste avec les bons éléments", {
  result <- import_biodiversity_data()
  expect_type(result, "list")
  expect_true(all(c("community_matrix", "sf_object", "raw_data") %in% names(result)))
})

test_that("community_matrix est une matrice avec des valeurs >= 0", {
  result <- import_biodiversity_data()
  expect_true(is.matrix(result$community_matrix))
  expect_true(all(result$community_matrix >= 0))
})

test_that("sf_object est bien un objet sf", {
  skip_if_not_installed("sf")
  result <- import_biodiversity_data()
  expect_s3_class(result$sf_object, "sf")
})

test_that("import_biodiversity_data echoue sans colonnes obligatoires", {
  bad_data <- data.frame(x = 1:5, y = 1:5)
  # Ecrire dans un CSV temporaire
  tmp <- tempfile(fileext = ".csv")
  write.csv(bad_data, tmp, row.names = FALSE)
  expect_error(import_biodiversity_data(tmp))
  unlink(tmp)
})

# ---- Tests : calculate_diversity_indices ----
test_that("calculate_diversity_indices retourne un data.frame", {
  result  <- import_biodiversity_data()
  indices <- calculate_diversity_indices(result$community_matrix)
  expect_s3_class(indices, "data.frame")
})

test_that("Shannon est toujours >= 0", {
  result  <- import_biodiversity_data()
  indices <- calculate_diversity_indices(result$community_matrix)
  expect_true(all(indices$shannon >= 0))
})

test_that("Simpson est entre 0 et 1", {
  result  <- import_biodiversity_data()
  indices <- calculate_diversity_indices(result$community_matrix)
  expect_true(all(indices$simpson >= 0 & indices$simpson <= 1))
})

test_that("Richesse specifique est un entier positif", {
  result  <- import_biodiversity_data()
  indices <- calculate_diversity_indices(result$community_matrix)
  expect_true(all(indices$richesse > 0))
  expect_true(all(indices$richesse == floor(indices$richesse)))
})

test_that("calculate_diversity_indices accepte un data.frame brut", {
  result  <- import_biodiversity_data()
  indices <- calculate_diversity_indices(result$raw_data)
  expect_s3_class(indices, "data.frame")
  expect_true("shannon" %in% names(indices))
})

# ---- Tests : calculate_landscape_metrics ----
test_that("calculate_landscape_metrics retourne un data.frame", {
  skip("sample_landcover non disponible")
})

test_that("Proportions sont entre 0 et 1", {
  skip("sample_landcover non disponible")
})
# ---- Tests : train_rf_model ----
test_that("train_rf_model retourne une liste avec les bons elements", {
  skip_if_not_installed("randomForest")
  set.seed(1)
  df <- data.frame(
    shannon       = runif(40, 0, 2),
    fragmentation = runif(40),
    prop_naturel  = runif(40),
    prop_agri     = runif(40)
  )
  res <- train_rf_model(df, target = "shannon", ntree = 50)
  expect_type(res, "list")
  expect_true(all(c("model", "importance", "train_data", "test_data") %in% names(res)))
})

test_that("train_rf_model echoue si target absent", {
  skip_if_not_installed("randomForest")
  df <- data.frame(x = 1:20, y = 1:20)
  expect_error(train_rf_model(df, target = "shannon"))
})

# ---- Tests : evaluate_model ----
test_that("evaluate_model retourne un data.frame avec train et test", {
  skip_if_not_installed("randomForest")
  set.seed(1)
  df <- data.frame(
    shannon       = runif(40, 0, 2),
    fragmentation = runif(40),
    prop_naturel  = runif(40)
  )
  res  <- train_rf_model(df, target = "shannon", ntree = 50)
  perf <- evaluate_model(res, target = "shannon", plot = FALSE)
  expect_s3_class(perf, "data.frame")
  expect_true(all(c("train", "test") %in% perf$set))
  expect_true(all(c("rmse", "r2", "mae") %in% names(perf)))
})
