library(shiny)
# Set the working directory and list all csv files inside

# Define UI for dataset viewer application
shinyUI(pageWithSidebar(

  # Application title.
  headerPanel("Performance "),

  sidebarPanel(
	wellPanel(
		selectInput("esServer", "Select Elasticsearch Server :", choices = c("perf19.perf.lab.eng.bos.redhat.com")),
		selectInput("esServerPort", "Select Elasticsearch Server :", choices = c("9200")),
		selectInput("esIndex", "Select the Elasticsearch index:", choices = c("pcp", "fsync2")),
		selectInput("host", "Select the host:", choices = c("gprfs016", "gprfs015")),
		#selectInput("stat", "Choose a dataset:",choices = c("CPU", "Memory", "Disk", "XFS")),
#		selectInput("stat", "Choose a dataset:",choices = c("disk","cpu", "memory","xfs")),
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
    h4("Write and Read IOPs"),
    plotOutput("plotCpu"),

    h4("CPU usage"),
    plotOutput("plotDisk"),

    h4("XFS"),
    plotOutput("plotXfsIops"),

    h4("XFS"),
    plotOutput("plotXfsAttr"),

    h4("Observations"),
   verbatimTextOutput("view")
  )
))
