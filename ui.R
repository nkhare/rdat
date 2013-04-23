library(shiny)
# Set the working directory and list all csv files inside

# Define UI for dataset viewer application
shinyUI(pageWithSidebar(

  # Application title.
  headerPanel("Performance "),

  sidebarPanel(
	wellPanel(
		selectInput("host", "Select the host:", choices = c("gprfs015", "gprfs016")),
		#selectInput("stat", "Choose a dataset:",choices = c("CPU", "Memory", "Disk", "XFS")),
		selectInput("stat", "Choose a dataset:",choices = c("disk.all.read","disk.all.write")),
#		downloadButton('downloadData', 'Download'),
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
    plotOutput("plot"),

    h4("Observations"),
   verbatimTextOutput("view")
  )
))
