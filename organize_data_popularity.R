# This script will create the popularity dataset from the Add Health publicly
# available wave 1 data.

# Load libraries ----------------------------------------------------------

source("check_packages.R")


# Set seed ----------------------------------------------------------------

# set the seed so I get same results
set.seed(39)


# Load the data -----------------------------------------------------------

# base data with most of what we want
load(here("input","add_health","21600-0001-Data.rda"))

# data for the number of nominations
load(here("input","add_health","21600-0003-Data.rda"))

# data for the weights
load(here("input","add_health","21600-0004-Data.rda"))



# Code variables ----------------------------------------------------------

# just grab the in-degree (number of nominations) and AID for networks
network <- da21600.0003 %>%
  select(AID,IDGX2) %>%
  rename(nominations=IDGX2) %>%
  mutate(AID=as.character(AID)) %>%
  filter(!is.na(nominations)) %>%
  tibble

# get weights
weights <- da21600.0004 %>%
  rename(cluster=CLUSTER2, sweight=GSWGT1) %>%
  mutate(AID=as.character(AID)) %>%
  tibble

# code base variables - this is the big one
addhealth <- da21600.0001 %>%
  mutate(AID=as.character(AID),
         race=ifelse(H1GI4=="(1) (1) Yes", "Latino",
                     str_trim(str_sub(H1GI9, 8))),
         race=factor(race, names(sort(table(race), decreasing=TRUE))),
         gender=factor(str_trim(str_sub(BIO_SEX, 8))),
         grade=as.numeric(H1GI20)+6,
         grade_english=ifelse(as.numeric(H1ED11)>4, NA, 5-as.numeric(H1ED11)),
         grade_math=ifelse(as.numeric(H1ED12)>4, NA, 5-as.numeric(H1ED12)),
         grade_history=ifelse(as.numeric(H1ED13)>4, NA, 5-as.numeric(H1ED13)),
         grade_science=ifelse(as.numeric(H1ED14)>4, NA, 5-as.numeric(H1ED14)),
         pseudo_gpa=(grade_english+grade_math+grade_science+grade_history)/4,
         honor_society=factor(ifelse(S44A31=="(1) (1) Marked", "Yes", "No")),
         bandchoir=factor(S44A13=="(1) (1) Marked" |
                            S44A15=="(1) (1) Marked" |
                            S44A16=="(1) (1) Marked", levels=c(FALSE,TRUE),
                          labels=c("No","Yes")),
         nsports=rowSums(across(paste("S44A",18:29,sep=""))=="(1) (1) Marked"),
         nsports=ifelse(nsports>6, 6, nsports),
         parent_income=ifelse(PA55>200, 200, PA55),
         alcohol_use=factor(H1TO12!="(0) (0) No (skip to Q.29)" &
                              H1TO15!="(6) (6) 1 or 2 days in past 12 months" &
                              H1TO15!="(5) (5) Once a month or less (3-12 times in past 12 months)" &
                              H1TO15!="(7) (7) Never (skip to Q.29)",
                            levels=c(FALSE,TRUE),
                            labels=c("Non-drinker","Drinker")),
         smoker=factor(H1TO1!="(0) (0) No (skip to Q.9)" &
                         H1TO2!="(00) (0) Never smoked a whole cigarette (skip to Q.9)" &
                         H1TO5>5, levels=c(FALSE,TRUE),
                       labels=c("Non-smoker","Smoker")),

         ) %>%
  select(AID, race, gender, grade, pseudo_gpa, honor_society, bandchoir,
         nsports, parent_income, alcohol_use, smoker) %>%
  tibble %>%
  left_join(weights) %>%
  right_join(network)


# Save files --------------------------------------------------------------

# now impute missing values
popularity  <- tibble(complete(mice(addhealth, 1)))
popularity <- popularity %>%
  select(grade, race, gender, nominations, alcohol_use, smoker, pseudo_gpa,
         honor_society, bandchoir, nsports, parent_income, cluster, sweight)

save(popularity, file=here("output","popularity.RData"))

