#Load required libraries
library(shiny)
library(DT)
library(readxl)
library(ggplot2)
library(plotly)
library(writexl)

#Sourcing the PCA code from PCA_Core for organisation
source('PCA_Core.R')

#Server logic for Uterine Fibroid Analysis
server <- function(input, output, session) {
  
  #Loading the metadata and combat_data into the server
  metadata <- read_xlsx('Master_for_R.xlsx', na = 'NA')
  data <- read.csv('combat_data.csv', row.names = 1)
  
  #Updates what graphs are displayed based on the selection of filters
  output$dynamic_filtering <- renderUI({
    filters_selected <- input$filters_selected
    filter_ui_elements <- list()
    
    #If age is selected provide a slider to select age ranges
    if ('age' %in% filters_selected) {
      filter_ui_elements$age <- sliderInput(
        inputId = 'age', 
        label = 'Age', 
        min = min(metadata$Age, na.rm = TRUE), 
        max = max(metadata$Age, na.rm = TRUE), 
        value = range(metadata$Age, na.rm = TRUE)
      )
    }
    
    #If BMI selected provide a slider to select BMI range
    if ('bmi' %in% filters_selected) {
      filter_ui_elements$bmi <- sliderInput(
        inputId = 'bmi', 
        label = 'BMI', 
        min = min(metadata$BMI, na.rm = TRUE), 
        max = max(metadata$BMI, na.rm = TRUE), 
        value = range(metadata$BMI, na.rm = TRUE)
      )
    }
    
    #If ethnicity selected provide check boxes for which ethnicity to include
    if ('ethnicity' %in% filters_selected) {
      filter_ui_elements$ethnicity <- checkboxGroupInput(
        inputId = 'ethnicity', 
        label = 'Ethnicity', 
        choices = unique(metadata$Ethnicity[!is.na(metadata$Ethnicity)])
      )
    }
    
    #If sample type selected provide check boxes for which sample type to include
    if ('sample_type' %in% filters_selected) {
      filter_ui_elements$sample_type <- checkboxGroupInput(
        inputId = 'sample_type', 
        label = 'Sample Type', 
        choices = unique(metadata$Sample_Type)
      )
    }
    
    #If gene is selected, make sure that other filters are selected, otherwise the gene box plot will not display
    if ('gene' %in% filters_selected) {
      if (length(setdiff(filters_selected, 'gene')) > 0) { #Makes sure no other filters are selected apart from gene
        showModal(modalDialog(
          title = 'Warning',
          'Please deselect all other filters to view Gene Expression Box Plot.', #Displaying warning code
          easyClose = TRUE,
          footer = modalButton('Close')
        ))
        
      #Allows the user to select or search for the gene they want if no other filters selected
      } else {
        filter_ui_elements$gene <- selectizeInput(
          inputId = 'gene_filter',
          label = 'Select Gene for Filtering',
          choices = rownames(data),
          multiple = TRUE,
          options = list(placeholder = 'Type to search for genes...', maxItems = 1)#Only one gene for the box plot as it gets too messy otherwise
        )
      }
    }
    
    do.call(tagList, filter_ui_elements)
  })
  
#-------------------------------FILTERING DATA----------------------------------
  filtered_metadata <- reactive({ #Reacts to the inputs of the filtering and updates metadata
    filtered_meta <- metadata
    
    if ('age' %in% input$filters_selected) {
      filtered_meta <- filtered_meta[!is.na(filtered_meta$Age), ] #Removes NA rows
      if (!is.null(input$age)) { #Checks user has changed slider values
        filtered_meta <- filtered_meta[filtered_meta$Age >= input$age[1] & filtered_meta$Age <= input$age[2], ] #If user has used slider, only include range specified by the user
      }
    }
    
    if ('bmi' %in% input$filters_selected) {
      filtered_meta <- filtered_meta[!is.na(filtered_meta$BMI), ] #Removes NA rows
      if (!is.null(input$bmi)) {
        filtered_meta <- filtered_meta[filtered_meta$BMI >= input$bmi[1] & filtered_meta$BMI <= input$bmi[2], ]
      }
    }
    
    if ('ethnicity' %in% input$filters_selected) {
      filtered_meta <- filtered_meta[!is.na(filtered_meta$Ethnicity), ] #Removes NA rows
      if (!is.null(input$ethnicity)) {
        filtered_meta <- filtered_meta[filtered_meta$Ethnicity %in% input$ethnicity, ]
      }
    }
    
    if ('sample_type' %in% input$filters_selected) {
      filtered_meta <- filtered_meta[!is.na(filtered_meta$Sample_Type), ] #Removes NA rows
      if (!is.null(input$sample_type)) {
        filtered_meta <- filtered_meta[filtered_meta$Sample_Type %in% input$sample_type, ]
      }
    }
    
    #Displays a valueBox showing the number of samples selected based on the filters applied
    output$samples_selected <- renderValueBox({
      valueBox(
        paste0(nrow(filtered_meta), ' Samples'),
        subtitle = 'Number of Samples Available',
        icon = icon('list'),
        color = 'aqua'
      )
    })
    
    filtered_meta
  })
  
  #Updates the gene expression data based on the user filters
  filtered_gene_data <- reactive({
    req(input$gene_filter) #Makes sure user has selected gene filter
    filtered_data <- data[rownames(data) %in% input$gene_filter, , drop = FALSE] #Only includes gene row that has been selected, keeping in dataframe
    filtered_data
  })
  
  #Creates tabs based on the plots available due to filters selected, updates sample count too
  output$dynamic_tabs <- renderUI({
    req(filtered_metadata())
    
    #If samples = 0 no data to present
    if (nrow(filtered_metadata()) == 0) {
      return(NULL)
    }
    
    tabs <- list()#Stores tabs based on filters
    
    #If age and bmi selected append the Age vs BMI Plot Tab
    if ('age' %in% input$filters_selected && 'bmi' %in% input$filters_selected) {
      tabs <- append(tabs, list(tabPanel('Age vs BMI', plotlyOutput('age_bmi_plot'))))
    }
    
    #If ethnicity selected append the Ethnicity Distribution Tab
    if ('ethnicity' %in% input$filters_selected) {
      tabs <- append(tabs, list(tabPanel('Ethnicity Distribution', plotlyOutput('ethnicity_plot'))))
    }
    
    #If gene selected append the Gene Expression Box Plot Tab
    if ('gene' %in% input$filters_selected && length(setdiff(input$filters_selected, 'gene')) == 0) { #Makes sure no other filters selected
      tabs <- append(tabs, list(tabPanel('Gene Expression Box Plot', plotlyOutput('gene_box_plot'))))
    }
    
    #PCA plot regardless of filters selected
    tabs <- append(tabs, list(tabPanel('PCA Plot', plotlyOutput('pca_plot'))))
    
    #Filtered Metadata Tab
    tabs <- append(tabs, list(tabPanel('Filtered Metadata', DTOutput('filtered_metadata_table'))))
    
    do.call(tabBox, c(width = 12, tabs)) #Tab Interface
  })
  
  #Creates the Age vs BMI plot if both of the filters are selected
  output$age_bmi_plot <- renderPlotly({
    req(input$filters_selected) #ensures that both bmi and age are selected
    req('age' %in% input$filters_selected)
    req('bmi' %in% input$filters_selected)
    
    #Creating the Age vs BMI plot
    p <- ggplot(filtered_metadata(), aes(x = Age, y = BMI, color = Sample_Type, text = paste('Sample:', GEO_ID, '<br>Paper:', Paper_ID))) +
      geom_point() +
      labs(title = 'Age vs BMI', x = 'Age', y = 'BMI') +
      theme_minimal()
    
    ggplotly(p, tooltip = 'text') #Allows user to see information on each point
  })
  
  #Creating the Ethnicity Distribution Plot 
  output$ethnicity_plot <- renderPlotly({
    req(input$filters_selected)
    req('ethnicity' %in% input$filters_selected)
    
    p <- ggplot(filtered_metadata(), aes(x = Ethnicity, fill = Sample_Type, text = paste('Sample:', GEO_ID, '<br>Paper:', Paper_ID))) +
      geom_bar() +
      labs(title = 'Ethnicity Distribution', x = 'Ethnicity', y = 'Count') +
      theme_minimal()
    
    ggplotly(p, tooltip = 'text')
  })
  
  #Creates the Gene Expression Box Plot only if the gene filter is selected and no other filter selected
  output$gene_box_plot <- renderPlotly({
    req(input$gene_filter)
    
    gene_data <- filtered_gene_data()
    gene_data_long <- reshape2::melt(as.data.frame(t(gene_data)), variable.name = 'Gene', value.name = 'Expression')
    gene_data_long$Sample_Type <- rep(filtered_metadata()$Sample_Type, each = length(input$gene_filter)) #Sample Type label added
    gene_data_long$Paper_ID <- rep(filtered_metadata()$Paper_ID, each = length(input$gene_filter)) #PaperID label added
    
    p <- ggplot(gene_data_long, aes(x = Gene, y = Expression, fill = Sample_Type)) +
      geom_boxplot() +
      labs(title = 'Gene Expression Box Plot', x = 'Gene', y = 'Expression Level') +
      theme_minimal() +
      facet_grid(~ Paper_ID, scales = 'free_y')
    
    ggplotly(p)
  })
  
    #Creates the PCA plot using the PCA_Core code
  output$pca_plot <- renderPlotly({
    req(filtered_metadata())
    
    filtered_geo_ids <- filtered_metadata()$GEO_ID
    filtered_data <- data[, filtered_geo_ids, drop = FALSE]
    
    metadata_modified_sel <- filtered_metadata()[order(filtered_metadata()$GEO_ID), ]
    log2_normalized_matrix <- filtered_data[, metadata_modified_sel$GEO_ID]
    
    pca_result <- CBF_PCA(
      data = t(log2_normalized_matrix),
      groups = metadata_modified_sel$Sample_Type,
      useLabels = FALSE,
      scale = FALSE,
      legendName = 'Sample Type'
    )
    
    ggplotly(pca_result, tooltip = c('x', 'y', "groups"))
  })
  
  #Table of the filtered metadata
  output$filtered_metadata_table <- renderDT({
    datatable(filtered_metadata())
  })
  
  #Allows for the data to be downloaded
  output$download_filtered <- downloadHandler(
    filename = function() { paste0('Fibroid_Analysis_Data', '.xlsx') },
    content = function(file) {
      filtered_geo_ids <- filtered_metadata()$GEO_ID
      filtered_data <- data[, filtered_geo_ids, drop = FALSE]
      
      #Seperates the data into metadata and expression data
      combined_data <- list(
        Metadata = filtered_metadata(),
        ExpressionData = as.data.frame(t(filtered_data))
      )
      
      writexl::write_xlsx(combined_data, path = file)
    }
  )

  #Instructions for how the App works appear at loading of app
  observe({
    showModal(modalDialog(
      title = 'Welcome to the Fibroid Analyis Dashboard',
      'To use this app, select which filters you would like to apply in the sidebar. If you want to view the Gene Expression Box Plot, deselect all other filters first. After applying filters, you can explore the available visualizations in the tabs. The data is also available for downloading too.',
      easyClose = TRUE,
      footer = modalButton('I Understand')
    ))
  })
}
