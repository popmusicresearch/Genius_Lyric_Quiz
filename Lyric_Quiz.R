#Install required pacakges
library(geniusr)
library(dplyr)
library(tidytext)
library(spotifyr)
library(tidyverse)
library(stringr)

#1: Establish connection with Genius API
#GENIUS API
key <- "<<YOUR KEY HERE>>"
secret <- "<< YOUR SECRET HERE"
GENIUS_API_TOKEN <- "<< YOUR TOKEN HERE>>"

#2 - Get Artist ID
artist_search <- "Teenage Fanclub"
artist <- search_artist(artist_search, n_results = 10, GENIUS_API_TOKEN)

#Check the artist dataframe to make sure you have the correct one.
head(artist)
#Get the correct ID - in most cases, this will be the first/only row. 
artist <- artist$artist_id[1]

#3 - Got songs
artist_songs <- get_artist_songs_df(
  artist,
  sort = c("title", "popularity"),
  include_features = FALSE,
  GENIUS_API_TOKEN
)

#Remove duplicated rows - some songs may appear more than once in the Genius dataset
artist_songs <- artist_songs[!duplicated(artist_songs$song_name), ]

#Remove 'Live' or 'Remix' - for example, live versions of remixes
artist_songs <- subset(artist_songs, !grepl("Live", song_name))
artist_songs <- subset(artist_songs, !grepl("Remix", song_name))

#4 - Get Lyrics
artist_lyrics <- data.frame() #create and empty dataframe to store lyrics
for (i in 1:nrow(artist_songs)) { #loop through each row s
  song <- artist_songs$song_id[i] #get individual song id
  print(paste("Getting lryics for", artist_songs$song_name[i])) #paste message to the console.
  try ({ #get lyrics for song, add to artist_lryics data frame.
    one_song <- get_lyrics_id(song_id = song, GENIUS_API_TOKEN)
    one_song$line_id <- 1:nrow(one_song)
    artist_lyrics <- rbind(artist_lyrics, one_song)
  })
  Sys.sleep(2) #introduce pause before attempting next row.
}

length(unique(artist_lyrics$song_name)) #compare songs returned with original list

#5 - Optional cleaning before Step 6 - 
#some of this could be handled in app as user input, but may be better done before

# Remove any line of lryics with fewer than 5 words
artist_lyrics <- artist_lyrics %>%
  filter(str_count(as.vector(line), "\\b\\w+\\b") > 5)

# Identify lyrics that are similar to the song title - if these appear as options in the quiz, it may be too easy.
library(stringdist)
artist_lyrics$diff <- stringdist(artist_lyrics$line, artist_lyrics$song_name, method = "cosine")
range(artist_lyrics$diff) #the lower the number, the higher the similarity between lyric and title

#For example, filtering on any diff value lower that .25
#You could potentially add a slider/other input to your app based on this value
# eg - a slider indicating difficulty that filters in/out similar lyrics.
artist_lyrics <- artist_lyrics %>%
  filter(diff > .25)

#Another option is to see if the completed song title is contained within the lyric
#artist_filtered <- artist_lyrics %>%
#  filter(!tolower(artist_lyrics$song_name) %in% tolower(artist_lyrics$line))

#6 - Write to data folder so that Shiny App can use it.
write_rds(artist_lyrics, "data/artist_lyrics.rds")








