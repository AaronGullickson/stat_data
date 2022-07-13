The Add Health data come from the publicly available files for Wave 1. These are not distributed with the repository but can be obtained directly from [Add Health](https://addhealth.cpc.unc.edu/data/). I use the pre-compiled R binary data distributed by Add Health:

* 21600-0001-data.rda: This is the main Wave I file that contains most of the student information.
* 21600-0003-data.rda: This file contains additional network data that I use to pull the number of friend nominations.
* 21600-0004-data.rda: This file contains sample weight and clustering data.

 These files should be placed in this directory to allow the `organize_data_popularity.R` script to work.
