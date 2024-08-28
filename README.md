# Fibroid Analysis Dashboard

## Overview

The purpose of the **Fibroid Analysis** app is that it allows users to explore and analyze data related to uterine fibroids. The app provides various filters, visualizations, and the ability to download filtered data for further analysis.

## Features

- **Dynamic Filtering**: Users can filter the dataset based on age, BMI, ethnicity, sample type, and gene expression.
- **Visualizations**:
  - **Age vs. BMI Plot**: Scatter plot to explore the relationship between age and BMI within the filtered dataset.
  - **Ethnicity Distribution**: Bar plot showing the distribution of ethnicities within the selected samples.
  - **Gene Expression Box Plot**: Box plots for selected gene(s) based on the filtered samples.
  - **PCA Plot**: Principal Component Analysis (PCA) plot to explore the variance in gene expression data.
- **Data Download**: Filtered metadata and expression data can be downloaded as an Excel file.

## Installation

To run this Shiny app locally, you need to have R installed on your machine along with the required packages.

### Required Packages

```r
install.packages(c("shiny", "shinydashboard", "DT", "readxl", "ggplot2", "plotly", "writexl", "reshape2"))


<img width="1707" alt="Screenshot 2024-08-28 at 17 40 12" src="https://github.com/user-attachments/assets/adc15ec9-c4bb-4420-a65a-e75208b5fec7">
