#Load required libraries
library(shiny)

#Sourcing both UI and Server
source("UI.R")
source("Server.R")

#Run App
shinyApp(ui = ui, server = server)