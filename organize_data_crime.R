# This script will create state level data on crime rates and demographic
# characteristics

# Load libraries ----------------------------------------------------------

source("check_packages.R")


# Get crime rates ---------------------------------------------------------

# I get crime rates from the Uniform Crime Reports API:
# https://crime-data-explorer.fr.cloud.gov/pages/docApi
# This requires an API key which can be requested here:
# https://api.data.gov/signup/

#replace this with your API key
api_key <- "WmW3SVDq3YIpgjxkfzGMNZsTataBMsheM70EAe0h"

# choose starting and ending year - crime rates will be averaged across
# years
start_year <- 2014
end_year <- 2018

urls <- paste("https://api.usa.gov/crime/fbi/sapi/api/estimates/states/",
              c(state.abb, "DC"), "/", start_year, "/", end_year, "?API_KEY=",
              api_key, sep="")

# query the API for each state and collect results
crimes <- map_dfr(urls, function(url) {
  results <- (curl::curl(url) %>% read_html() %>% html_nodes("p") %>%
                html_text %>% fromJSON)$results %>%
    bind_rows %>%
    mutate(violent_rate=100000*violent_crime/population,
           property_rate=100000*property_crime/population,
           year=2014:2018) %>%
    select(state_id, state_abbr, year, violent_rate, property_rate)

  return(results)
})

# average results across years
# the state_id here is not FIPS code (WTF, UCR?) so I will just match
# on state abbreviations
crimes <- crimes %>%
  group_by(state_abbr) %>%
  summarize(violent_rate=mean(violent_rate),
            property_rate=mean(property_rate))


# Get FIPS crosswalk ------------------------------------------------------

# I need a crosswalk file to go from FIPS to state abbreviations
# I found one here:
# http://staff.washington.edu/glynn/StateFIPSicsprAB.pdf
crosswalk <- read_excel(here("input","social_explorer",
                             "fips_abbr_crosswalk.xls")) %>%
  rename(fips=FIPS, state_abbr=AB) %>%
  select(fips, state_abbr)

# Get demographic characteristics -----------------------------------------

# Demographic characteristics come from the ACS 2014-18 extracted via
# Social Explorer

acs <- read_csv(here("input","social_explorer","R13155148_SL040.csv"),
                skip=1)

crimes <- acs %>%
  rename(state=Geo_NAME,
         pop_total=SE_A02001_001, pop_male=SE_A02001_002,
         median_age=SE_A01004_001,
         pop_25over=SE_B12001_001, pop_25over_lhs=SE_B12001_002,
         pop_labor_force=SE_A17005_001, pop_unemployed=SE_A17005_003,
         median_income=SE_A14006_001, gini=SE_A14028_001,
         pop_families=SE_A13002_001, pop_families_pov=SE_A13002_002) %>%
  mutate(fips=as.numeric(Geo_FIPS),
         percent_male=100*pop_male/pop_total,
         percent_lhs=100*pop_25over_lhs/pop_25over,
         unemploy_rate=100*pop_unemployed/pop_labor_force,
         poverty_rate=100*pop_families_pov/pop_families,
         gini=100*gini) %>%
  left_join(crosswalk) %>% # to get state abbreviations
  right_join(crimes) %>% # merge it all together
  select(state, state_abbr, violent_rate, property_rate, median_age,
         percent_male, percent_lhs, median_income, gini, unemploy_rate,
         poverty_rate)

# Save the data -----------------------------------------------------------

save(crimes, file=here("output","crimes.RData"))
