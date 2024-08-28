#Load required libraries
library(shiny)
library(shinydashboard)

ui <- dashboardPage(
  
#------------------------------------HEADER-------------------------------------
  
  dashboardHeader(title = 'Fibroid Analysis Dashboard'),
  
#-----------------------------------SIDEBAR-------------------------------------

  dashboardSidebar(
    
    #Adding University of Liverpool Image
    tags$div(style = 'text-align: center;',
             img(src = 'P12-UoL-Logo-CMYK.png', height = '50px')),
    
    #Check boxes for Filters to be applied
    tags$div(style = 'font-size: 20px;',
      checkboxGroupInput(
        inputId = "filters_selected", #Tracks selected filters
        label = tags$span('Select Filters:', style = 'font-size: 30px;'),
        choices = list('Age' = 'age',
                       'BMI' = 'bmi',
                       'Ethnicity' = 'ethnicity',
                       'Sample Type' = 'sample_type',
                       'Gene' = 'gene'),
        selected = NULL #So no filters are selected at the start
      )
    ),
    
    #Dynamic filtering for when filter selected
    uiOutput('dynamic_filtering'), #Change to 'dynamic filtering'
    
    #Download Button
    div(style = 'margin-top: 10px; text-align: center;', 
        downloadButton('download_filtered', 'Download Data',
                       style = 'background-color: #337ab7; color: white; font-size: 16px;'))
  ),
  
#-----------------------------------BODY----------------------------------------

  #Main content area of dasboard
  dashboardBody(
    fluidRow(
      valueBoxOutput('samples_selected') #Displays number of samples selected based on filters
    ),
    uiOutput('dynamic_tabs') #Only specific plots for certain filters
  )
)
