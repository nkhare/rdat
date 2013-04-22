library(shiny)
# Set the working directory and list all csv files inside
av.datasets = list.files(pattern="*csv")
ops = read.csv("ops.csv")

# Define UI for dataset viewer application
shinyUI(pageWithSidebar(

  # Application title.
  headerPanel("Volume profile results for different calls - Anshi"),

  sidebarPanel(
	wellPanel(
		selectInput("stat", "Choose a dataset:",choices = ops$stat),
		numericInput("obs", "Number of observations to view:", 10),
		submitButton("Update View")
	),
	wellPanel(
		h4("Configuration and Workload"),
#		helpText('storage.batched-fsync: on'),
		helpText('cluster.eager-lock: on'),
		helpText('thread: 10'),
		helpText('filesize: 32'),
		helpText('files: 50000 per thread'),
		helpText('operation: create')
	)
  ),
	
  mainPanel(
    h4("Average Latency Over runs - grpfs016 Brick"),
    plotOutput("plot")

#    h4("Observations"),
 #   tableOutput("view")
  )
))
