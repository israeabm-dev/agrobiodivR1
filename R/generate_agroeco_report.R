#' Générer un rapport agroécologique automatique (HTML)
#'
#' Nouvelle fonctionnalité : Génère un rapport HTML interactif complet
#' combinant les indices de biodiversité, une carte interactive Leaflet,
#' les métriques paysagères et les résultats du modèle RF.
#'
#' @param biodiv_result Liste retournée par \code{import_biodiversity_data}.
#' @param indices Data.frame retourné par \code{calculate_diversity_indices}.
#' @param landscape_metrics Data.frame retourné par \code{calculate_landscape_metrics}.
#' @param model_result Liste retournée par \code{train_rf_model} (optionnel).
#' @param output_file Chemin du fichier HTML de sortie.
#'   Défaut: "rapport_agroecologique.html" dans le répertoire courant.
#' @param title Titre du rapport. Défaut: "Rapport Agroécologique - agrobiodivR".
#' @param open Logique. Ouvrir automatiquement le rapport. Défaut: TRUE.
#'
#' @return Chemin absolu vers le fichier HTML généré (invisiblement).
#'
#' @importFrom rmarkdown render
#'
#' @export
#'
#' @examples
#' \dontrun{
#' \dontrun{
#' bd      <- import_biodiversity_data()
#' indices <- calculate_diversity_indices(bd$community_matrix)
#' lc      <- import_landcover()
#' metrics <- calculate_landscape_metrics(lc)
#' generate_agroeco_report(bd, indices, metrics,
#'                         output_file = "mon_rapport.html")
#' }
#' }
generate_agroeco_report <- function(biodiv_result,
                                     indices,
                                     landscape_metrics,
                                     model_result  = NULL,
                                     output_file   = "rapport_agroecologique.html",
                                     title         = "Rapport Agroécologique - agrobiodivR",
                                     open          = TRUE) {

  # Vérification des dépendances
  if (!requireNamespace("rmarkdown", quietly = TRUE)) {
    stop("Le package 'rmarkdown' est requis. Installez-le avec install.packages('rmarkdown').")
  }
  if (!requireNamespace("leaflet", quietly = TRUE)) {
    stop("Le package 'leaflet' est requis. Installez-le avec install.packages('leaflet').")
  }

  # Création du template Rmd temporaire
  template_rmd <- tempfile(fileext = ".Rmd")

  rmd_content <- sprintf('---
title: "%s"
date: "`r Sys.Date()`"
output:
  html_document:
    theme: flatly
    toc: true
    toc_float: true
    code_folding: hide
---

```{r setup, include=FALSE}
knitr::opts_chunk$set(echo = FALSE, warning = FALSE, message = FALSE)
library(ggplot2)
library(leaflet)
```

## 1. Biodiversité terrain

```{r biodiv-table}
knitr::kable(indices, caption = "Indices de biodiversité par parcelle",
             digits = 3)
```

```{r shannon-plot}
ggplot(indices, aes(x = reorder(parcelle, shannon), y = shannon, fill = shannon)) +
  geom_bar(stat = "identity") +
  coord_flip() +
  scale_fill_viridis_c() +
  labs(title = "Indice de Shannon par parcelle", x = "Parcelle", y = "H\'") +
  theme_minimal() +
  theme(legend.position = "none")
```

## 2. Carte des observations

```{r leaflet-map}
if (!is.null(biodiv_result$sf_object)) {
  pts <- biodiv_result$sf_object
  coords <- sf::st_coordinates(pts)
  leaflet::leaflet() %%>%%
    leaflet::addTiles() %%>%%
    leaflet::addCircleMarkers(
      lng    = coords[, 1],
      lat    = coords[, 2],
      radius = 6,
      color  = "darkgreen",
      popup  = paste("Espèce :", pts$espece,
                     "<br>Abondance :", pts$abondance,
                     "<br>Parcelle :", pts$parcelle)
    )
} else {
  cat("Aucune donnée spatiale disponible.")
}
```

## 3. Métriques paysagères

```{r landscape-table}
knitr::kable(landscape_metrics, caption = "Métriques paysagères", digits = 3)
```

```{r landscape-plot}
if ("fragmentation" %%in%% names(landscape_metrics)) {
  ggplot(landscape_metrics, aes(x = prop_naturel, y = shannon_paysage,
                                 size = fragmentation, color = prop_agriculture)) +
    geom_point(alpha = 0.8) +
    scale_color_viridis_c(name = "Prop. Agriculture") +
    labs(title = "Naturalité vs Diversité paysagère",
         x = "Proportion habitats naturels",
         y = "Shannon paysager") +
    theme_minimal()
}
```

## 4. Modèle prédictif

```{r model-section, results="asis"}
if (!is.null(model_result)) {
  cat("### Importance des variables\\n")
  print(knitr::kable(model_result$importance, digits = 3,
                     caption = "Importance des variables (%%IncMSE)"))
} else {
  cat("*Aucun modèle fourni.*")
}
```

---
*Rapport généré par le package [agrobiodivR](https://github.com/votre-username/agrobiodivR)*
', title)

  # Remplacer les échappements Rmd (nécessaires dans sprintf)
  rmd_content <- gsub("%%%%in%%%%", "%in%", rmd_content)
  rmd_content <- gsub("%%%%>%%%%", "%>%", rmd_content)

  writeLines(rmd_content, template_rmd)

  # Sauvegarder les objets dans un environnement temporaire
  tmp_env <- new.env()
  tmp_env$biodiv_result    <- biodiv_result
  tmp_env$indices          <- indices
  tmp_env$landscape_metrics <- landscape_metrics
  tmp_env$model_result     <- model_result

  # Rendu
  message("Génération du rapport HTML...")
  output_path <- rmarkdown::render(
    input       = template_rmd,
    output_file = normalizePath(output_file, mustWork = FALSE),
    envir       = tmp_env,
    quiet       = TRUE
  )

  message("Rapport généré : ", output_path)

  if (open && interactive()) {
    utils::browseURL(output_path)
  }

  invisible(output_path)
}
