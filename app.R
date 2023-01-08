### LOAD HELPER FILES
source('helpers/load_packages.R', local = TRUE) #Load required R Packages
source('helpers/misc.R', local = TRUE)  #Functions

#UI
ui <- fluidPage(
  
  ### CSS  
  tags$head(
    tags$link(rel = "stylesheet", type = "text/css", href = "quiz_app_style.css")
  ),
  
  useShinyjs(),  # include shinyjs library
  
  # TITLE
  h1("The Teenage Fanclub Lyrics Quiz"),
  hr(),
  uiOutput("intro"),
  h4(uiOutput("question_number")),
  h2(uiOutput("question")),
  hr(),
  actionButton(inputId = "start_quiz", label = "Start Quiz", style ="color: #010203; background-color: #c7fbfc; border-color: #9c7c38"),
  uiOutput("answers"),
  actionButton(inputId = "submit", label = "Submit", style ="color: #010203; background-color: #c7fbfc; border-color: #074283"),
  h4(uiOutput("selected")),
  p(),
  actionButton(inputId = "next_question", label = "Next Lyric", style ="color: #010203; background-color: #c7fbfc; border-color: #074283"),
  p(),
  uiOutput("your_score"),
  h3(uiOutput("your_final_score")),
  p(),
  actionButton(inputId = "play_again", label = "Play Again?", style ="color: #010203; background-color: #c7fbfc; border-color: #074283"),
  actionButton("twitter_share",
               label = "Share on Twitter",
               icon = icon("twitter"),
               onclick = sprintf("window.open('%s')", url), 
               style ="color: #FFFFFF; background-color: #0955a8; border-color: #0955a8"),
  h6(includeMarkdown('app_markdown_files/quiz_app_footer_text.md'))
)

# Define server logic required to draw a histogram
server <- function(input, output, session) {
  
  #hide buttons
  show("intro")
  hide("question_number")
  hide("question")
  hide("answers")
  hide("submit")
  hide("your_score")
  hide("next_question")
  hide("selected")
  hide("your_final_score")
  hide("play_again")
  hide("twitter_share")
  
  output$intro <- renderText({
    "The lyrics for 192 songs by <b>Teenage Fanclub</b> were scraped from the Genius API. This app randomly selects a lyric from one of those songs, and will then provide the titles of three songs. Can you correctly identify which song the lyric came from? Sometimes the app will randomly select a line that will give the game away...but sometimes the lyric might be a little harder to place. You will have 25 questions, and will receive a score at the end. Click the Start Quiz button to play. Good luck! "
  })
  
  # Initialize counter to 1
  counter <- reactiveValues()
  counter$row <- 1
  counter$score <- 0
  counter$data <- NULL
  
  observeEvent(input$start_quiz, {
    hide("intro")
    hide("start_quiz")
    show("question_number")
    show("question")
    show("answers")
  })
  
  data_sample <- reactive({
    lyrics <- readRDS('data/artist_lyrics.rds')
    data <- prepQuiz(lyrics)
    data_sample <- data[counter$row, ]
  }) 
  
  output$question_number <- renderText({
    paste("Lyric ", counter$row, " of 25", sep = "")
  })
  
  output$question <- renderText({
    data_sample <- data_sample()
    data_sample$question[1]
  })
  
  output$answers <- renderUI({
    data_sample <- data_sample()
    songs <- c(data_sample$answer1[1], data_sample$answer2[1], data_sample$answer3[1])
    songs <- sample(songs)
    radioButtons("answers", "Which song does that come from?", songs, selected = character(0))
  })
  
  output$selected <- renderText({
    data_sample <- data_sample()
    if (is.null(input$answers)) {
      ""
    }
    else if (input$answers == data_sample$answer1[1]) {
      paste("<b>Correct!</b> That line is from ", "<b>", data_sample$answer1[1], "</b>", sep="")
    } else {
      paste("<b>Nope!</b> That line is from ", "<b>",data_sample$answer1[1], "</b>", sep="")
    }
  })
  
  observeEvent(input$answers, {
    show("submit")
    data_sample <- data_sample()
    current_score <- counter$score
    if ((input$answers == data_sample$answer1[1])) {
      current_score <- current_score + 1
    } else {
      current_score <- current_score
    }
    counter$score <- current_score
  })
  
  output$your_score <- renderText({
    paste("Your score is ", counter$score, " out of a possible ", counter$row, ". You are currently at ", 
          round(counter$score/counter$row*100, 2), "%.", sep="")
  })
  
  output$your_final_score <- renderText({
    paste("You scored ", counter$score, " out of a possible ", counter$row, sep="")
  })
  
  observeEvent(input$submit, {
    if (counter$row < 25) {
      hide("submit")
      hide("answers")
      show("selected")
      show("your_score")
      show("next_question")
    } else {
      hide("submit")
      hide("answers")
      show("selected")
      show("your_final_score")
      show("play_again")
      show("twitter_share")
    }
  })
  
  observeEvent(input$next_question, {
    counter$row <- counter$row + 1
    hide("next_question")
    hide("submit")
    hide("your_score")
    hide("selected")
  })
  
  observeEvent(input$play_again, {
    counter$row <- 1
    counter$score <- 0
    data_sample <- reactive({
      lyrics <- readRDS('data/artist_lyrics.rds')
      data <- prepQuiz(lyrics)
      data_sample <- data[counter$row, ]
    }) 
    hide("play_again")
    hide("your_final_score")
    hide("twitter_share")
    hide("selected")
    show("question")
    show("answers")
  })

}

# Run the application 
shinyApp(ui = ui, server = server)
