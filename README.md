# ResPrj_HIA_Indonesia_pm25_mortality_1998_2020

This is an [R targets](https://github.com/ropensci/targets) pipeline for the health impact assessment of PM<sub>2.5</sub> exposure in Indonesia on all-cause mortality. It has been developed on R 4.5.1 "Great Square Root" and RStudio 2025.05.1 "Mariposa Orchid". Input data is sourced from publicly available datasets only.

The pipeline can be adapted to conduct a health impact assessment for a different region, time period and dataset sources. Read more at the attached [GitHub Pages](https://cardat.github.io/ResPrj_HIA_Indonesia_pm25_mortality_1998_2020/).

## Data

Modelled mortality and population data is produced by the [Institute of Health Metrics and Evaluation (IHME)](https://www.healthdata.org/) as part of the Global Burden of Disease study. It can be downloaded from IHME's Global Health Data Exchange - [GBD Results Tool](https://vizhub.healthdata.org/gbd-results/). You must register to search and download data. 

Modelled PM<sub>2.5</sub> surfaces are published by the [Atmospheric Composition Analysis Group](https://sites.wustl.edu/acag/). The SatPM2.5 dataset is periodically updated - the latest version is available [here](https://sites.wustl.edu/acag/datasets/surface-pm2-5/). Older versions are accessible in the [SatPM2.5 Archive](https://sites.wustl.edu/acag/datasets/surface-pm2-5-archive/).

Geographical boundaries for various administrative levels across the world are drawn from the [Database of Global Administrative Areas](https://gadm.org/index.html) and is freely available for academic use only.

The dataset versions used in the development of this pipeline are available in the [CARDAT data repository](https://cloud.car-dat.org/), accessible to approved researchers only.

