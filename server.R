library(shiny)
library(RCurl)
library(rjson)
library(datasets)
library(ggplot2)

# Define server logic required to summarize and view the selected dataset
shinyServer(function(input, output) {

        # Return the requested dataset
	hostname <- reactive(function() {
		res = input$host
		res
	})

        # Return the requested stat matrix
	statMatrix <- reactive(function() {
	stat = input$stat
	stat
	})
	
	# Read the content from Elastic Search Server
	readElasticSearch <- function() {
		host1 = hostname()
 		url=paste0("http://perf19.perf.lab.eng.bos.redhat.com:9200/_search?source={%22size%22:3600,%22query%22:{%22bool%22:{%22must%22:[{%22term%22:{%22PS.hostname%22:%22",host1,"%22}}]}},%22sort%22:[{%22timestamp.s%22:{%22order%22:%22asc%22}}]}")
		raw=getURL(url)
		data=fromJSON(raw)
		hits=data$hits$hits
		hits
	}

	getvalue <- function(l, k) {
		value = l$"_source"$values[k][[1]]$instances[[1]]$value
	}

	gettimestamp <- function(l) {
		t = l$"_source"$timestamp$s
		t
	}

	getname <- function(l) {
		  name = l$name
	}
	
	gethits <- function() {
                x = readElasticSearch()
                x
	}

	getTimestamps <- function() {			
		hits = readElasticSearch()
		timestamps = sapply(hits, gettimestamp)
		t = as.POSIXct(timestamps, origin="1970-01-01","%H:%M:%S")
		t	
	}

	getValues <- function() {
		hits = readElasticSearch()
		names = sapply(hits[[1]]$"_source"$values, getname)
		namesCount =  (length(names))

		values = list()
		for (i in 1:namesCount) {
		  v = sapply(hits, getvalue, i) 
		  values[[names[i]]] = list(v)
		}
		values
	}
	
	output$plot <- renderPlot({
		timeseries = getTimestamps()
		stat = statMatrix()
		v = getValues()
		df <- data.frame(t1=timeseries,y=unlist(v[stat]))	
		p <- ggplot() + geom_point(aes(x=t1,y=y), df)
		print(p)
	  })

#	output$view = renderPrint ({
#		x = getValues()
#		x
#	})
})
