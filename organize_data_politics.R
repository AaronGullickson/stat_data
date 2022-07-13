# This sscript will create an analytical politics dataset from the ANES
# data

# Load libraries ----------------------------------------------------------

source("check_packages.R")

# Set seed ----------------------------------------------------------------

# set the seed so I get same results
set.seed(39)

# Load the data -----------------------------------------------------------

politics <- read_dta(here("input","anes","anes_timeseries_2016.dta"))


# Demographic Variables ---------------------------------------------------

## Age
politics$age <- ifelse(politics$V161267<0, NA,  politics$V161267)
summary(politics$age)

## Highest degree
politics$educ <- factor(ifelse(politics$V161270<0, NA,
                               ifelse(politics$V161270<=8, "Less than HS",
                                      ifelse(politics$V161270==9,"High school diploma",
                                             ifelse(politics$V161270<13,"Some college",
                                                    ifelse(politics$V161270<14,"Bachelors degree", "Graduate degree"))))),
                        levels=c("Less than HS","High school diploma","Some college","Bachelors degree","Graduate degree"))
table(politics$V161270, politics$educ, exclude=NULL)


## Military Service
politics$military <- factor(ifelse(politics$V161274a<0, NA,
                                   ifelse(politics$V161274a==0, "No","Yes")),
                            levels=c("No","Yes"))
table(politics$V161274a, politics$military, exclude=NULL)


## Work status
politics$workstatus <- factor(ifelse(politics$V161277<0, NA,
                                     ifelse(politics$V161277==1, "Working",
                                            ifelse(politics$V161277<5, "Unemployed", "Not in Labor Force"))),
                              levels=c("Not in Labor Force","Unemployed","Working"))
table(politics$V161277, politics$workstatus, exclude=NULL)

## Race
politics$race <- factor(ifelse(politics$V161310x<0, NA, politics$V161310x),
                        levels=c(1,2,5,3,4,6),
                        labels=c("White","Black","Latino","Asian/Pacific Islander","American Indian","Other/Mixed"))
table(politics$V161310x, politics$race, exclude=NULL)

## Gender
politics$gender <- factor(ifelse(politics$V161342<0, NA,
                                 ifelse(politics$V161342==1,"Male",
                                        ifelse(politics$V161342==2,"Female","Other"))),
                          levels=c("Other","Male","Female"))
table(politics$V161342, politics$gender, exclude=NULL)

## Religion - this one is complicated. Need to combine non-exclusive self-identity
## with services most commonly attends
politics$fundamentalist <- ifelse(politics$V161266a<0, NA, politics$V161266a==1)
politics$pentecostal <- ifelse(politics$V161266b<0, NA, politics$V161266b==1)
politics$evangelical <- ifelse(politics$V161266c<0, NA, politics$V161266c==1)
politics$bornagain <- ifelse(politics$V161266d<0, NA, politics$V161266c==1)
politics$traditional <- ifelse(politics$V161266e<0, NA, politics$V161266e==1)
politics$mainline <- ifelse(politics$V161266f<0, NA, politics$V161266f==1)
politics$progressive <- ifelse(politics$V161266g<0, NA, politics$V161266g==1)
politics$nontrad <- ifelse(politics$V161266h<0, NA, politics$V161266h==1)
politics$secular <- ifelse(politics$V161266j<0, NA, politics$V161266j==1)
politics$agnostic <- ifelse(politics$V161266k<0, NA, politics$V161266k==1)
politics$aethist <- ifelse(politics$V161266m<0, NA, politics$V161266m==1)
politics$spiritual <- ifelse(politics$V161266n<0, NA, politics$V161266n==1)

politics$relig <- factor(ifelse(politics$V161247a<0, NA, politics$V161247a),
                         levels=1:4,
                         labels=c("Protestant","Catholic","Jewish","Other"))
politics$relig_nonattend <- factor(ifelse(politics$V161247b<0, NA, politics$V161247b),
                                   levels=1:4,
                                   labels=c("Protestant","Catholic","Jewish","Other"))
politics$relig[is.na(politics$relig)] <- politics$relig_nonattend[is.na(politics$relig)]

politics$nonrelig <- politics$secular | politics$agnostic | politics$aethist
politics$nonrelig <- ifelse(is.na(politics$nonrelig), FALSE, politics$nonrelig)
politics$evangelical <- !politics$nonrelig & (politics$fundamentalist | politics$pentecostal |
                                                politics$evangelical | politics$bornagain)
politics$evangelical <- ifelse(is.na(politics$evangelical), FALSE, politics$evangelical)

politics$relig <- factor(ifelse((!is.na(politics$relig) & (politics$relig=="Protestant" | politics$relig=="Other")) & politics$evangelical, "Evangelical Protestant",
                                ifelse(politics$nonrelig, "Non-religious",
                                       ifelse(politics$relig=="Protestant","Mainline Protestant",as.character(politics$relig)))),
                         levels=c("Mainline Protestant","Evangelical Protestant","Catholic","Jewish","Non-religious","Other"))


## Income - cant get specific income value, only brackets but I need more quant variables so lets randomize
## amount within the bracket
low <- c(1,5,10,12.5,15,17.5,20,22.5,25,27.5,30,35,40,45,50,55,60,65,70,75,80,90,100,110,125,150,175,250)
high <- c(low[2:28],300)
mid <- (low+high)/2
indx <- ifelse(politics$V161361x<1, NA, politics$V161361x)
politics$income <- round(low[indx]+runif(nrow(politics))*(high[indx]-low[indx]),0)


## Political Party
politics$party <- factor(ifelse(politics$V161155<1, NA, politics$V161155),
                         levels=c(1,2,3,5),
                         labels=c("Democrat","Republican","Independent","Other"))
table(politics$V161155, politics$party, exclude=NULL)


# Voting and Beliefs ------------------------------------------------------

## Presidential Vote
politics$president <- factor(ifelse(politics$V162062x < -1, NA,
                                    ifelse(politics$V162062x>2, 3, politics$V162062x)),
                             levels=c(1:3,-1),
                             labels=c("Clinton","Trump","Other","No Vote"))
table(politics$V162034a, politics$president, exclude=NULL)

## Anthropogenic Global Warming
politics$globalwarm <- factor(ifelse(politics$V161221<0 | politics$V161222<0, NA,
                                     ifelse(politics$V161221==2 | politics$V161222==2, "No", "Yes")),
                                     levels=c("No","Yes"))
table(politics$V161221, politics$V161222, politics$globalwarm, exclude=NULL)


## Birthright Citizenship
politics$brcitizen <- factor(ifelse(politics$V161194x<0, NA,
                                     ifelse(politics$V161194x<3,3,
                                            ifelse(politics$V161194x>4, 5, politics$V161194x))),
                              levels=5:3,
                              labels=c("Oppose","Neither","Favor"))
table(politics$V161194x, politics$brcitizen, exclude=NULL)

## Gay Marriage
politics$gaymarriage <- factor(ifelse(politics$V161231<0, NA, politics$V161231),
                               levels=c(3:1),
                               labels=c("No legal recognition","Civil unions","Support gay marriage"))
table(politics$V161231, politics$gaymarriage, exclude=NULL)

## Transgender bathrooms
politics$trans_bath <- factor(ifelse(politics$V161228<0, NA, politics$V161228),
                              levels=1:2,
                              labels=c("No","Yes"))
table(politics$V161228, politics$trans_bath, exclude=NULL)

# Finalize Dataset --------------------------------------------------------

# remove missing values on president
politics <- politics %>%
  filter(!is.na(president)) %>%
  select(age, gender, race, workstatus, military, educ, income, relig, party,
         president, globalwarm, brcitizen, gaymarriage)

#impute data
politics <- tibble(complete(mice(politics, 1)))

#save the new data
save(politics, file=here("output","politics.RData"))
