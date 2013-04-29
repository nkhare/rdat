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
		selectInput("esIndex", "Select the Elasticsearch index:", choices = c("test", "pcp", "fsync2", "fsync2nobarrier")),
		selectInput("host", "Select the host:", choices = c("gprfs016", "gprfs015")),
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
    h4("Disk Throughput MB/s"),
    plotOutput("plotDiskThroughput"),
#    downloadButton("downloadDiskThroughputData", "Download Disk Throughput Data"),

    h4("XFS Throughput MB/s"),
    plotOutput("plotXfsThroughput"),

    h4("Disk Write and Read IOPs"),
    plotOutput("plotDisk"),

    h4("XFS - Filesystem IOPS"),
    plotOutput("plotXfsIops"),

    h4("XFS Set/Get Xattr"),
    plotOutput("plotXfsAttr"),

    h4("CPU usage"),
    plotOutput("plotCpu"),

    h4("Memory Usage"),
    plotOutput("plotMemory")

 #   h4("Observations"),
 #   verbatimTextOutput("view")
  )
))
