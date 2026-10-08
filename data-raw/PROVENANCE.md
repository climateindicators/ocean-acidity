# Provenance

Every file in this directory is reproduced unmodified from EPA's published
indicator page and its per-figure data downloads. To update the data, replace the
file and rerun `Rscript R/build_data.R`.

## Indicator page

- `source-page.html`  \
  <https://19january2025snapshot.epa.gov/climate-indicators/climate-change-indicators-ocean-acidity/index.html>  \
  sha256 `6b7e6a4248ea806cb80588f6d77b97a896b22cd1a9d51585dedfdb0cdc54b876`

Technical documentation: <https://19january2025snapshot.epa.gov/system/files/documents/2024-06/acidity_documentation.pdf>

## Figure data

- `ocean-acidity_fig-1.csv`  \
  <https://19january2025snapshot.epa.gov/system/files/other-files/2024-06/ocean-acidity_fig-1.csv>  \
  sha256 `6897484857317e3ed3550a73b7f0f90745155ad9e71014698a1561fc1dd6559d`  \
  encoding windows-1252, 415 data rows, columns: `Hawaii Year`, `Hawaii pH`, `Hawaii pCO2`, ``, `Canary Islands Year`, `Canary Islands pH`, `Canary Islands pCO2`, ``, `Bermuda Year`, `Bermuda pH`, `Bermuda pCO2`, ``, `Cariaco Year (pH)`, `Cariaco pH`, `Cariaco Year (pCO2)`, `Cariaco pCO2`  \
  title: Figure 1. Ocean Carbon Dioxide Levels and Acidity, 1983-2022  \
  data source: Bates, 2016; González-Dávila, 2012; University of South Florida, 2021; University of Hawaii, 2023; web update: June 2024; units: pH; partial pressure in micro-atmospheres

- **Figure 2** has no data download on EPA's page. The narrative carries the caption; there is nothing to build.

- **Figure 3** has no data download on EPA's page. The narrative carries the caption; there is nothing to build.

## Figure images

Figures 2 and 3 have no data, so EPA's own published image is shown instead.
These live in `../images/`, reproduced unmodified from EPA's "download image"
links.

- `images/acidity_download2_2024.png`  \
  <https://19january2025snapshot.epa.gov/system/files/images/2024-06/acidity_download2_2024.png>  \
  sha256 `22111a116b2c4d6f03a7ded7592581cf16410e8f139e4c37908f60d2ee8a6cbd`  \
  Figure 2. Changes in Aragonite Saturation of the World's Oceans, 1880-2015

- `images/acidity_download-ph-scale_2021.png`  \
  <https://19january2025snapshot.epa.gov/sites/default/files/2021-04/acidity_download-ph-scale_2021.png>  \
  sha256 `1c4d2a518c71ab495759b78a64189243e7338c35548d338f949b477e86a25ae9`  \
  Figure 3. pH Scale
