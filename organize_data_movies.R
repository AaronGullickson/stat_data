# This script will load the basic IMDB data and then use the OMDB API
# to scrape extra data. The scraping takes awhile and you need to have
# an api key that will allow you to get about 91K entries.

# Load libraries ----------------------------------------------------------

source("check_packages.R")

# Load and clean basic IMDB data ------------------------------------------

imdb <- read_delim("https://datasets.imdbws.com/title.basics.tsv.gz", delim="\t",
                   na="\\N", quote='') %>%
  # basic filters
  filter(titleType=="movie" & isAdult==0 & startYear>=2000) %>% #basic filters
  # runtime filter - Screen Actor's guild says 80 minutes for a feature film
  # no upper limit for a feature film, but Return of the King is 201, so
  # lets set it at 3.5 hours
  filter(runtimeMinutes>=80 & runtimeMinutes <=210) %>%
  # also filter out some genres
  filter(!is.na(genres) &
           !str_detect(genres, "Adult") &
           !str_detect(genres, "Documentary") &
           !str_detect(genres, "News") &
           !str_detect(genres, "Game-Show") &
           !str_detect(genres, "Reality-TV") &
           !str_detect(genres, "Talk-Show")) %>%
  rename(title=primaryTitle, year=startYear, runtime=runtimeMinutes) %>%
  # Pick one genre for each
  mutate(genre=factor(case_when(
    str_detect(genres, "Animation") ~ "Animation",
    str_detect(genres, "Family") ~ "Family",
    str_detect(genres, "Western") ~ "Western",
    str_detect(genres, "Biography") ~ "Biography",
    str_detect(genres, "Music") ~ "Musical",
    str_detect(genres, "Horror") ~ "Horror",
    str_detect(genres, "Sci-Fi") ~ "Sci-Fi/Fantasy",
    str_detect(genres, "Fantasy") ~ "Sci-Fi/Fantasy",
    str_detect(genres, "Comedy") ~ "Comedy",
    str_detect(genres, "Sport") ~ "Sport",
    str_detect(genres, "Romance") ~ "Romance",
    str_detect(genres, "Action") ~ "Action",
    str_detect(genres, "Thriller") ~ "Thriller",
    str_detect(genres, "Mystery") ~ "Mystery",
    str_detect(genres, "Drama") ~ "Drama",
    TRUE ~ "Other"))) %>%
  select(tconst, title, year, runtime, genre)

# get all genres
#genres <- str_trim(str_split(toString(imdb$genres), ",", simplify=TRUE)[1,])
#sort(unique(genres))
#table(genres)

# Merge IMDB rating data --------------------------------------------------

imdb <- read_delim("https://datasets.imdbws.com/title.ratings.tsv.gz",
                           delim="\t", na="\\N", quote='') %>%
  rename(rating_imdb=averageRating, votes_imdb=numVotes) %>%
  right_join(imdb, by="tconst") %>%
  select(tconst, title, year, runtime, genre, rating_imdb) %>%
  filter(!is.na(rating_imdb))


# Scrape other data -------------------------------------------------------

#test <- imdb[sample(1:nrow(imdb), 100),]

scraped_data <- map_dfr(imdb$tconst, function(x){

  url <- str_c("http://www.omdbapi.com/?apikey=e55e952f&tomatoes=true&i=", x)
  if(!url.exists(url)) {
    return(NULL)
  }

  #print(x)

  # read OMDB page
  title_page <- curl::curl(url) %>% read_html()

  #grab JSON data
  omdb <- title_page %>% html_nodes("p") %>% html_text %>% fromJSON

  # Output for each movie
  return(list("tconst"=x,
              "maturity_rating"=ifelse(omdb$Rated=="N/A", NA, omdb$Rated),
              "metascore" = ifelse(omdb$Metascore=="N/A", NA,
                                   parse_number(omdb$Metascore)),
              "box_office" = ifelse(omdb$BoxOffice=="N/A", NA,
                                    parse_number(omdb$BoxOffice)),
              "awards" = str_extract(omdb$Awards, "(?<=Won\\s)(\\d+)(?=\\sOscar)"),
              "english" = ifelse(omdb$Language=="N/A", NA,
                                 str_detect(omdb$Language, "English")),
              "domestic" = ifelse(omdb$Country=="N/A", NA,
                                  str_detect(omdb$Country, "United States|USA"))))
})

movies <- scraped_data %>%
  mutate(awards=ifelse(is.na(awards), 0, awards),
         maturity_rating=factor(maturity_rating,
                                levels=c("G","PG","PG-13","R")),
         box_office=round(box_office/1000000,1)) %>%
  right_join(imdb) %>%
  filter(!is.na(maturity_rating) & !is.na(metascore) & !is.na(box_office)) %>%
  filter(english & domestic & box_office > 0) %>%
  select(title, year, runtime, maturity_rating, genre, box_office,
         rating_imdb, metascore, awards)

save(movies, file=here("output","movies.RData"))
