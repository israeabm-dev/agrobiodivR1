#' Données de biodiversité terrain simulées
#'
#' Jeu de données d'exemple contenant des observations de biodiversité
#' simulées pour 10 parcelles agricoles au Maroc.
#'
#' @format Un data.frame avec 200 lignes et 5 variables :
#' \describe{
#'   \item{espece}{Nom de l'espèce observée}
#'   \item{abondance}{Nombre d'individus comptés}
#'   \item{parcelle}{Identifiant de la parcelle (P01 à P10)}
#'   \item{lon}{Longitude (WGS84, degrés décimaux)}
#'   \item{lat}{Latitude (WGS84, degrés décimaux)}
#' }
#'
#' @source Données simulées à des fins pédagogiques.
#'   Pour des données réelles, voir GBIF (\url{https://www.gbif.org}).
"sample_biodiversity"

#' Raster d'occupation du sol simulé
#'
#' Raster SpatRaster (terra) d'exemple représentant l'occupation du sol
#' sur une zone agricole au Maroc occidental.
#'
#' @format Un objet SpatRaster (terra) avec les valeurs :
#' \describe{
#'   \item{1}{Agriculture}
#'   \item{2}{Forêt}
#'   \item{3}{Prairie}
#'   \item{4}{Urbain}
#'   \item{5}{Eau}
#' }
#'
#' @source Données simulées. Pour des données réelles, utiliser
#'   Corine Land Cover (\url{https://land.copernicus.eu/pan-european/corine-land-cover})
#'   ou ESA WorldCover (\url{https://worldcover2021.esa.int}).
"sample_landcover"
