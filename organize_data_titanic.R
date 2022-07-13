# This script will load in the raw Titanic data and organize it for the
# class examples


# Load libraries ----------------------------------------------------------

source("check_packages.R")

# Set seed ----------------------------------------------------------------

# set the seed so I get same results
set.seed(39)

# Load and code titanic data ----------------------------------------------

# The Titanic data here come from TITANIC3 inm the PASWR2 library
titanic <- tibble(
  survival=factor(TITANIC3$survived, levels=1:0, labels=c("Survived","Died")),
  sex=factor(TITANIC3$sex, levels=c("female","male"),
             labels=c("Female","Male")),
  age=TITANIC3$age,
  pclass=factor(as.character(TITANIC3$pclass), levels=c("1st","2nd","3rd"),
                labels=c("First","Second","Third")),
  fare=TITANIC3$fare,
  family=TITANIC3$sibsp+TITANIC3$parch
)

# impute values
titanic <- tibble(complete(mice(titanic, 1)))

# now create age group variable
titanic <- titanic %>%
  mutate(agegroup=factor(age>=16, levels=c(FALSE,TRUE),
                         labels=c("Child","Adult")),
         name=TITANIC3$name) %>%
  select(name, survival, sex, age, agegroup, pclass, fare, family)

# Save file ---------------------------------------------------------------

save(titanic, file=here("output","titanic.RData"))

