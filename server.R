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

	esServer <- reactive(function() {
		res = input$esServer 
		res
	})

	esPort <- reactive(function() {
		res = input$esServerPort
		res
	})
	esIndex <- reactive(function() {
		res = input$esIndex
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
		elasticServer = esServer()
		elasticPort = esPort()
		index = esIndex()
		cat(elasticPort)
 		url=paste0("http://",elasticServer,":",elasticPort,"/",index,"/","/_search?source={%22size%22:3600,%22query%22:{%22bool%22:{%22must%22:[{%22term%22:{%22PS.hostname%22:%22",host1,"%22}}]}},%22sort%22:[{%22timestamp.s%22:{%22order%22:%22asc%22}}]}")
		cat(url)
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

	diffList <- function(l) {
		ldiff = list()
		l = unlist(l)
		for (i in 2:length(l)) {ldiff[i-1] = l[[i]] - l[[i-1]] }
		ldiff
	}
	
	
	output$plotCpu <- renderPlot({
		timeseries = getTimestamps()
		timeseries = timeseries[-1]
		stat = statMatrix()
		v = getValues()
		reads = v["disk.all.read"]
		reads = diffList(reads)
		reads = unlist(reads)
		writes = v["disk.all.write"]
		writes = diffList(writes)
		writes = unlist(writes)
		df <- data.frame(time = timeseries, readsIops = reads, writeIops = writes)
		p <-  ggplot() + geom_line(aes(time, readsIops, colour="reads"), df) + geom_line(aes(time, writeIops, colour="writes"), df)
		print(p)
		})
	output$plotDisk <- renderPlot({
		timeseries = getTimestamps()
		timeseries = timeseries[-1]
		stat = statMatrix()
		v = getValues()
		cpuUser = unlist(diffList(v["kernel.all.cpu.user"]))
		cpuNice = unlist(diffList(v["kernel.all.cpu.nice"]))
		cpuSys = unlist(diffList(v["kernel.all.cpu.sys"]))
		cpuIdle = unlist(diffList(v["kernel.all.cpu.idle"]))
		cpuIntr = unlist(diffList(v["kernel.all.cpu.intr"]))
		df <- data.frame(time = timeseries, user = cpuUser, nice = cpuNice, sys = cpuSys, idle = cpuIdle, intr = cpuIntr )#, nice = CpuNice)
		p <- ggplot() + geom_line(aes(time, user, colour="user"), df) + geom_line(aes(time, nice, colour="nice"), df) + geom_line(aes(time, sys, colour="sys"), df) + geom_line(aes(time, idle, colour="idle"), df) + geom_line(aes(time, intr, colour="intr"), df) 
		print(p)
	})

	output$plotXfsIops <- renderPlot ({
		timeseries = getTimestamps()
		timeseries = timeseries[-1]
		stat = statMatrix()
		v = getValues()
		xfsReads = unlist(diffList(v["xfs.read"]))
		xfsWrites = unlist(diffList(v["xfs.write"]))
		xfsReadbytes = unlist(diffList(v["xfs.read_bytes"]))
		xfsWritebytes = unlist(diffList(v["xfs.write_bytes"]))
		xfsLogWrites = unlist(diffList(v["xfs.log.writes"]))
		xfsIflush = unlist(diffList(v["xfs.iflush_count"]))
		df <- data.frame(time = timeseries, readsIops = xfsReads, writeIops = xfsWrites, logWriteIops = xfsLogWrites,  xfsIflushCount = xfsIflush )
		write.csv(df, "/tmp/xfs.csv")
		p <-  ggplot() + geom_line(aes(time, readsIops, colour="xfsReads"), df) + geom_line(aes(time, writeIops, colour="xfsWrites"), df) + geom_line(aes(time, logWriteIops, colour="xfsLogWrites"), df) +  geom_line(aes(time, xfsIflushCount, colour="xfsIflush"), df)
		print(p)

	})

	output$plotXfsAttr <- renderPlot ({
		timeseries = getTimestamps()
		timeseries = timeseries[-1]
		stat = statMatrix()
		v = getValues()
		xfsSetattr = unlist(diffList(v["xfs.attr.set"]))
		xfsGetattr = unlist(diffList(v["xfs.attr.get"]))
		df <- data.frame(time = timeseries, xfsSetattrCount = xfsSetattr, xfsGetattrCount = xfsGetattr)
		p <-  ggplot()  + geom_line(aes(time, xfsSetattrCount , colour="xfsSetattr"), df) + geom_line(aes(time, xfsGetattrCount, colour="xfsGetattr"), df) + scale_y_log10() 
		print(p)

	})
	output$view = renderPrint ({
		v = getValues()
		reads1 = v["xfs.read"]
		x = unlist(diffList(reads1))
		cat(x)
	})
})
