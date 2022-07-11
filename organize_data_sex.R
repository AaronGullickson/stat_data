# This script will read in the GSS extract of sexual frequency data

# Load libraries ----------------------------------------------------------

source("check_packages.R")


# Set seed ----------------------------------------------------------------

# set the seed so I get same results
set.seed(39)

# Read in data ------------------------------------------------------------

sex <- read_fwf(here("input","gss","GSS.dat"),
                col_positions = fwf_widths(
                  widths = rep(7,10),
                  col_names=c("sexornt","ballot","marstat","age", "educ",
                              "sex","religion", "fund", "sexfreq", "year")))

# Clean data --------------------------------------------------------------

sex <- sex %>%
  mutate(age = ifelse(age<0, NA, age), #age is missing if negative
         educ = ifelse(educ<0, NA, educ), #educ is missing if negative
         gender = factor(sex, levels=1:2, labels=c("Male","Female")),
         # for marital status, I collapse separated with divorced and then
         # reorder
         marital = factor(ifelse(marstat==4, 3, marstat), levels=c(5,1,3,2),
                          labels=c("Never married","Married","Divorced",
                                   "Widowed")),
         relig=factor(case_when(
           religion < 0 ~ NA_character_,
           (religion==1 | religion==11) & fund==1 ~ "Evangelical Protestant",
           (religion==1 | religion==11) ~ "Mainline Protestant",
           religion==2 ~ "Catholic",
           religion==3 ~ "Jewish",
           religion==4 ~ "None",
           TRUE ~ "Other"),
           levels=c("Evangelical Protestant","Mainline Protestant","Catholic",
                    "Jewish","Other","None")),
         sexorient=factor(sexornt, levels=c(3,1,2),
                          labels=c("Heterosexual","Gay or Lesbian","Bisexual")),
         sexf=case_when(sexfreq==1 ~ 1.5,
                        sexfreq==2 ~ 12,
                        sexfreq==3 ~ 30,
                        sexfreq==4 ~ 52,
                        sexfreq==5 ~ 104, #lets assume twice a week
                        sexfreq==6 ~ 156)) %>%
  select(sexf, gender, age, marital, sexorient, relig, educ)


# Impute missing values ---------------------------------------------------

sex <- complete(mice(sex, m=1))

# Apply the gamma ---------------------------------------------------------

# standard scale seems to work ok
sex$sexf <- round(rgamma(nrow(sex), sex$sexf))

# Save the dataset --------------------------------------------------------

save(sex, file=here("output","sex.RData"))

