# This script will read in the 2018 CPS data on wages, extracted through
# the IPUMS system

# Load libraries ----------------------------------------------------------

source("check_packages.R")

# Set seed ----------------------------------------------------------------

# set the seed so I get same results
set.seed(39)

# Read in Data ------------------------------------------------------------

cps <- read_fwf(here("input","cps","cps_00003.dat.gz"),
                col_positions =
                  fwf_positions(
                    start = c(1,10,67,69,70,73,74,81,82,85,87,92,101,104,106,
                              111,121,125,126,127,135,140),
                    end   = c(4,11,68,69,72,73,74,81,84,86,87,95,103,105,108,
                              120,124,125,126,134,137,140),
                    col_names = c("year","month","age","sex","race","marst",
                                  "nchild","nativity","hispan","empstat",
                                  "labforce","occ2010","ahrsworkt","wkstat",
                                  "educ","earningwt","hourwage","paidhour",
                                  "union","earnweek","uhrswork","eligorg")),
                #ensure that all variables are read in as integers
                col_types = cols(.default = "i"),
                progress = FALSE)

#adjust some variables for decimal places
cps$earningwt <- cps$earningwt/10000
cps$hourwage <- cps$hourwage/100
cps$earnweek <- cps$earnweek/100

# Calculate Hourly Wage ---------------------------------------------------

#use hourly wage if provided
cps$wages <- ifelse(cps$hourwage==99.99, NA, cps$hourwage)
summary(cps$wages)
tapply(is.na(cps$wages), cps$paidhour, mean)

#use earnings last week and hours worked in a typical week for cases paidhour==1
cps$ahrsworkt <- ifelse(cps$ahrsworkt==999, NA, cps$ahrsworkt)
tapply(is.na(cps$ahrsworkt), cps$paidhour, sum)
cps$wages <- ifelse(cps$paidhour==1, cps$earnweek/cps$ahrsworkt, cps$wages)
summary(cps$wages)
tapply(cps$wages, cps$paidhour, summary)

#how many wages below $1?
sum(cps$wages<1, na.rm=TRUE)

#remove all missing wages and wages less than $1
cps <- subset(cps, !is.na(wages) & wages>=1)

#top-code wages from salary at $99.99/hour
cps$wages <- ifelse(cps$wages>99.99, 99.99, cps$wages)
summary(cps$wages)
ggplot(cps, aes(x=wages, y=..density..))+
  geom_histogram(fill="grey", color="black")+
  geom_density(alpha=0.5, fill="grey")+
  theme_bw()


# Code Other Variables ----------------------------------------------------

cps <- cps %>%
  mutate(gender=factor(sex, levels=1:2, labels=c("Male","Female")),
         racecombo=factor(case_when(
           hispan > 0 ~ "Latino",
           race==100 ~ "White",
           race==200 ~ "Black",
           race==300 | race==652 ~ "Indigenous",
           race==651 ~ "Asian",
           TRUE ~ "Other/Multiple"),
           levels=c("White","Black","Latino","Asian","Indigenous",
                    "Other/Multiple")),
         marstat=factor(case_when(
           marst==1 | marst==2 ~ "Married",
           marst==3 | marst==4 ~ "Divorced/Separated",
           marst==5 ~ "Widowed",
           marst==6 ~ "Never Married"),
           levels=c("Never Married","Married","Divorced/Separated","Widowed")),
         foreign_born=factor(ifelse(nativity==0, NA,
                                    ifelse(cps$nativity==5, "Yes", "No")),
                             levels=c("No","Yes")),
         education=factor(case_when(
           educ==999 ~ NA_character_,
           educ<73 ~ "No HS Diploma",
           educ<90 ~ "HS Diploma",
           educ<111 ~ "AA Degree",
           educ<123 ~ "Bachelors Degree",
           TRUE ~ "Graduate Degree"),
           levels=c("No HS Diploma","HS Diploma","AA Degree","Bachelors Degree",
                    "Graduate Degree")),
         earn_type=factor(ifelse(paidhour==1, "Salary",
                                    ifelse(paidhour==2, "Wage", NA))),
         occup=factor(case_when(
           occ2010<430 ~ "Manager",
           occ2010<1000 ~ "Business/Finance Specialist",
           occ2010<2000 ~ "STEM",
           occ2010<2100 ~ "Social Services",
           occ2010<2200 ~ "Legal",
           occ2010<2600 ~ "Education",
           occ2010<3000 ~ "Arts, Design, and Media",
           occ2010<=3120 & occ2010!=3110 ~ "Doctors",
           occ2010<3600 ~ "Other Healthcare",
           occ2010<4700 ~ "Service",
           occ2010<5000 ~ "Sales",
           occ2010<6000 ~ "Administrative Support",
           TRUE ~ "Manual"),
           levels=c("Manual","Administrative Support", "Sales", "Service",
                    "Social Services", "Other Healthcare",
                    "Arts, Design, and Media", "Education","Legal","Doctors",
                    "STEM","Business/Finance Specialist","Manager"))
  )

table(cps$gender, cps$sex, exclude=NULL)
table(cps$race, cps$racecombo, exclude=NULL)
table(cps$hispan, cps$racecombo, exclude=NULL)
table(cps$marst, cps$marstat, exclude=NULL)
table(cps$nativity, cps$foreign_born, exclude=NULL)
table(cps$educ, cps$education, exclude=NULL)
table(cps$earn_type, cps$paidhour, exclude=NULL)
table(cps$occup, exclude=NULL)


# Finalize Dataset --------------------------------------------------------

#limit this to ages 18 to 65
#only 171 missing values for foreign born so just drop

earnings <- cps %>%
  filter(age>=18 & age<65 & !is.na(foreign_born)) %>%
  mutate(race=racecombo) %>%
  select(wages, age, gender, race, marstat, education, occup, nchild,
         foreign_born, earn_type, earningwt)


save(earnings, version=2, file=here("output","earnings.RData"))
