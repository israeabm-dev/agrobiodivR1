# agrobiodivR <img src="man/figures/logo.png" align="right" height="120" alt="agrobiodivR logo"/>

> Analyse de la Biodiversité Agraire et Connectivité des Habitats

[![R](https://img.shields.io/badge/R-≥4.1-blue.svg)](https://cran.r-project.org/)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![Package version](https://img.shields.io/badge/version-0.1.0-green.svg)](DESCRIPTION)

---

## Description

`agrobiodivR` est un package R dédié à l'analyse agroécologique. Il permet de :

- 🌿 Calculer des **indices de biodiversité** (Shannon, Simpson, richesse spécifique)
- 🗺️ Analyser les **paysages agricoles** via des métriques paysagères
- 🔬 Mesurer la **fragmentation des habitats**
- 🔗 Évaluer la **connectivité écologique** et identifier des corridors
- 🌲 Modéliser la relation **agriculture ↔ biodiversité** avec Random Forest
- 📊 Générer des **rapports HTML automatiques** avec cartes interactives

---

## Installation

```r
# Installer devtools si nécessaire
install.packages("devtools")

# Installer agrobiodivR depuis GitHub
devtools::install_github("votre-username/agrobiodivR")
```

### Dépendances principales

| Package | Usage |
|---------|-------|
| `sf` | Données vectorielles spatiales |
| `terra` | Données raster |
| `vegan` | Calcul des indices de biodiversité |
| `randomForest` | Modélisation RF |
| `ggplot2` | Visualisations |
| `leaflet` | Cartes interactives |
| `rmarkdown` | Rapports automatiques |

---

## Utilisation rapide

```r
library(agrobiodivR)

# 1. Importer les données de biodiversité
bd <- import_biodiversity_data()

# 2. Calculer les indices
indices <- calculate_diversity_indices(bd$community_matrix)
print(indices)

# 3. Charger l'occupation du sol
lc <- import_landcover()

# 4. Métriques paysagères
metrics <- calculate_landscape_metrics(lc)

# 5. Distances aux habitats naturels
dist_result <- calculate_distance_to_habitat(lc, bd$sf_object)

# 6. Connectivité écologique
conn <- analyze_connectivity(lc, max_distance_m = 500)
cat("Indice de connectivité :", conn$connectivity_index)

# 7. Clustering des paysages
clustered <- cluster_landscapes(metrics)

# 8. Modèle Random Forest
rf <- train_rf_model(model_data, target = "shannon")
evaluate_model(rf)

# 9. Rapport HTML (fonctionnalité bonus)
generate_agroeco_report(bd, indices, metrics, output_file = "rapport.html")
```

---

## Fonctions du package

| Fonction | Description |
|----------|-------------|
| `import_biodiversity_data()` | Import CSV/Excel, conversion sf, matrice communautés |
| `calculate_diversity_indices()` | Shannon, Simpson, richesse, équitabilité |
| `import_landcover()` | Import raster CLC/ESA, reclassification, découpage |
| `calculate_landscape_metrics()` | Fragmentation, diversité paysage, proportion habitats |
| `calculate_distance_to_habitat()` | Raster distance aux habitats naturels |
| `analyze_connectivity()` | Indice connectivité, corridors potentiels |
| `cluster_landscapes()` | K-means sur métriques paysagères |
| `train_rf_model()` | Random Forest biodiversité ~ paysage |
| `evaluate_model()` | RMSE, R², graphiques Observé vs Prédit |
| `generate_agroeco_report()` | ⭐ Rapport HTML avec carte Leaflet (bonus) |

---

## Sources de données fiables

- **GBIF** — Données de biodiversité terrain : <https://www.gbif.org>
- **Corine Land Cover (CLC)** — Occupation du sol Europe : <https://land.copernicus.eu/pan-european/corine-land-cover>
- **ESA WorldCover** — Occupation du sol mondiale : <https://worldcover2021.esa.int>
- **OpenStreetMap** — Données géographiques libres : <https://www.openstreetmap.org>

---

## Structure du projet

```
agrobiodivR/
├── R/                          # Fonctions du package
│   ├── import_biodiversity_data.R
│   ├── calculate_diversity_indices.R
│   ├── import_landcover.R
│   ├── calculate_landscape_metrics.R
│   ├── calculate_distance_to_habitat.R
│   ├── analyze_connectivity.R
│   ├── cluster_landscapes.R
│   ├── train_rf_model.R
│   ├── evaluate_model.R
│   ├── generate_agroeco_report.R   ← Fonctionnalité bonus
│   └── data.R                  # Documentation des datasets
├── data/                       # Données .rda
│   ├── sample_biodiversity.rda
│   └── sample_landcover.rda
├── data-raw/                   # Scripts de création des données
│   └── create_sample_data.R
├── inst/extdata/               # Données brutes CSV
│   └── sample_biodiversity.csv
├── man/                        # Documentation auto-générée (roxygen2)
├── tests/testthat/             # Tests unitaires
│   ├── helper.R
│   └── test-diversity.R
├── vignettes/                  # Tutoriels reproductibles
│   └── agrobiodivR-intro.Rmd
├── DESCRIPTION
├── NAMESPACE
└── README.md
```

---

## Développement

```r
# Charger les outils de développement
library(devtools)

# Générer la documentation
devtools::document()

# Vérifier le package (CRAN check)
devtools::check()

# Installer localement
devtools::install()

# Lancer les tests
devtools::test()

# Construire la vignette
devtools::build_vignettes()
```

---

## Auteur

Package développé par **Israe Ait-Oubrahim** dans le cadre du cours de programmation R.

## Licence

MIT © 2025
