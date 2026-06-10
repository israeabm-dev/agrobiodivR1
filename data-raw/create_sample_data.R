## Script de création des jeux de données d'exemple
## Exécuter avec : source("data-raw/create_sample_data.R")

set.seed(42)

# ---- 1. sample_biodiversity ----
# Données de terrain simulées pour 10 parcelles et 15 espèces
parcelles <- paste0("P", sprintf("%02d", 1:10))
especes   <- paste0("sp_", c("Papilio_machaon", "Bombus_terrestris",
                               "Perdix_perdix", "Alauda_arvensis",
                               "Vanessa_atalanta", "Apis_mellifera",
                               "Miliaria_calandra", "Ciconia_ciconia",
                               "Lepus_europaeus", "Vulpes_vulpes",
                               "Carabus_auratus", "Gryllus_campestris",
                               "Luscinia_megarhynchos", "Buteo_buteo",
                               "Falco_tinnunculus"))

n <- 200
sample_biodiversity <- data.frame(
  espece    = sample(especes, n, replace = TRUE,
                     prob = c(0.12, 0.10, 0.08, 0.09, 0.07,
                               0.10, 0.06, 0.04, 0.05, 0.03,
                               0.08, 0.06, 0.05, 0.04, 0.03)),
  abondance = rpois(n, lambda = 4) + 1,
  parcelle  = sample(parcelles, n, replace = TRUE),
  lon       = runif(n, -5.5, -1.0),   # Bounding box Maroc occidental
  lat       = runif(n, 33.0, 36.0),
  date_obs  = sample(seq(as.Date("2023-03-01"), as.Date("2023-10-31"), by = "day"), n, replace = TRUE),
  observateur = sample(c("Obs_A", "Obs_B", "Obs_C"), n, replace = TRUE)
)

# ---- 2. sample_landcover (SpatRaster simulé) ----
# Raster 30x30 cellules simulant l'occupation du sol
if (requireNamespace("terra", quietly = TRUE)) {
  r <- terra::rast(nrows = 30, ncols = 30,
                   xmin = -5.5, xmax = -1.0,
                   ymin = 33.0, ymax = 36.0,
                   crs  = "EPSG:4326")

  # Classes : 1=Agriculture(50%), 2=Forêt(20%), 3=Prairie(15%), 4=Urbain(10%), 5=Eau(5%)
  set.seed(42)
  vals <- sample(1:5, terra::ncell(r), replace = TRUE,
                 prob = c(0.50, 0.20, 0.15, 0.10, 0.05))
  terra::values(r) <- vals
  names(r) <- "landcover"
  levels(r) <- data.frame(
    id    = 1:5,
    label = c("Agriculture", "Foret", "Prairie", "Urbain", "Eau")
  )
  sample_landcover <- r
} else {
  sample_landcover <- NULL
  warning("terra non disponible : sample_landcover non créé.")
}

# ---- Sauvegarde ----
usethis::use_data(sample_biodiversity, overwrite = TRUE)
if (!is.null(sample_landcover)) {
  usethis::use_data(sample_landcover, overwrite = TRUE)
}

message("Jeux de données créés et sauvegardés dans data/")
