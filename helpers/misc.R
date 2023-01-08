##DEFINE THE FUNCTION THAT GENERATES THE QUIZ
prepQuiz <- function(x) {
  y <- sample_n(x, size = 50, replace = FALSE, weight = NULL) %>%
    distinct(song_name, .keep_all = TRUE) %>%
    select(line, song_name) %>%
    rename(question = line,
           answer1 = song_name)
  y <- sample_n(y, 25)
  y$answer2 <- NA
  y$answer3 <- NA
  for (i in 1:nrow(y)) {
    song_sample <- x %>%
      filter(song_name != y$answer1[i]) %>%
      distinct(song_name, .keep_all = TRUE) %>%
      sample_n(2)
    y$answer2[i] <- song_sample$song_name[1]
    y$answer3[i] <- song_sample$song_name[2]
  }
  y$correct <- y$answer1
  return(y)
}

##TEXT FOR CREATING TWEET
url <- "https://twitter.com/intent/tweet?text=I%20just%20played%20the%20Teenage%20Fanclub%20Lyrics%20Quiz%20by%20@craigfots%20Click%20here%20to%20have%20a%20go&url=https://craigfots.shinyapps.io/tfc_quiz/"



