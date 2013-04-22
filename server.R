library(shiny)
library(RCurl)
library(rjson)


# Define server logic required to summarize and view the selected dataset
shinyServer(function(input, output) {

        # Return the requested dataset
	datasetInput = reactive(function() {
	res = input$stat
	res
	})
  # Generate a summary of the dataset
  output$plot <- renderPlot({
	stat <- datasetInput()
	url="http://perf19.perf.lab.eng.bos.redhat.com:9200/_search?source={%22query%22:{%22match_all%22:{}},%22sort%22:[{%22timestamp.s%22:{%22order%22:%22asc%22}}]}"
	raw=getURL(url)
	data=fromJSON(raw)

	getname <- function(l) {
	  name = l$name
	}

	gettimestamp <- function(l) {
	  t = l$"_source"$timestamp$s
	}

	getvalue <- function(l, k) {
	  #print(l)
	  value = l$"_source"$values[k][[1]]$instances[[1]]$value
	}

	hits=data$hits$hits
    
	names = sapply(hits[[1]]$"_source"$values, getname)
	print(names)
	namesCount =  (length(names))

	values = list()
	for (i in 1:namesCount) {
	  #print(names[i])
	  v = sapply(hits, getvalue, i) 
	  #print(typeof(v))
	  values[[names[i]]] = list(v)
	}

	timestamps = sapply(hits, gettimestamp)
	print (typeof(timestamps))

	t = as.POSIXct(timestamps, origin="1970-01-01","%H:%M:%S")
	print (t)

 	plot(t,unlist(values[stat]))
  })

  # Show the first "n" observations
#  output$view <- renderTable({
 #   head(datasetInput(), n = input$obs)
  #})
})
