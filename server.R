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

	kbsToGb <- function(bytes) {
		mbs = bytes / (1024 * 1024)
		mbs = round(mbs, 2)
		mbs
	}

	bytesToMb <- function(bytes) {
		mbs = bytes / (1024 * 1024)
		mbs = round(mbs, 2)
		mbs
	}
	
	output$plotDisk <- renderPlot({
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
		p <-  ggplot() + geom_line(aes(time, readsIops, colour="reads"), df) + geom_line(aes(time, writeIops, colour="writes"), df) + xlab("Time") + ylab("IOPS") + theme(legend.title=element_blank()) + theme(legend.text = element_text(colour="blue", size = 16))
		print(p)
		})

	output$plotCpu <- renderPlot({
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
		p <- ggplot() + geom_line(aes(time, user, colour="user"), df) + geom_line(aes(time, nice, colour="nice"), df) + geom_line(aes(time, sys, colour="sys"), df) + geom_line(aes(time, idle, colour="idle"), df) + geom_line(aes(time, intr, colour="intr"), df) +  xlab("Time") + ylab("CPU Usage") + theme(legend.title=element_blank()) + theme(legend.text = element_text(colour="blue", size = 16))

		print(p)
	})

	output$plotXfsIops <- renderPlot({
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
#		write.csv(df, "/tmp/xfs.csv")
		p <-  ggplot() + geom_line(aes(time, readsIops, colour="xfsReads"), df) + geom_line(aes(time, writeIops, colour="xfsWrites"), df) + geom_line(aes(time, logWriteIops, colour="xfsLogWrites"), df) +  geom_line(aes(time, xfsIflushCount, colour="xfsIflush"), df) + xlab("Time") + ylab("XFS IOPS") + theme(legend.title=element_blank()) + theme(legend.text = element_text(colour="blue", size = 16))
		print(p)

	})

	output$plotXfsAttr <- renderPlot({
		timeseries = getTimestamps()
		timeseries = timeseries[-1]
		stat = statMatrix()
		v = getValues()
		xfsSetattr = unlist(diffList(v["xfs.attr.set"]))
		xfsGetattr = unlist(diffList(v["xfs.attr.get"]))
		df <- data.frame(time = timeseries, xfsSetattrCount = xfsSetattr, xfsGetattrCount = xfsGetattr)
		p <-  ggplot()  + geom_line(aes(time, xfsSetattrCount , colour="xfsSetattr"), df) + geom_line(aes(time, xfsGetattrCount, colour="xfsGetattr"), df) + xlab("Time") + ylab("XFS Xattr OP Count") + theme(legend.title=element_blank()) + theme(legend.text = element_text(colour="blue", size = 16))
		print(p)

	})
	

	output$plotMemory <- renderPlot({
		timeseries = getTimestamps()
		stat = statMatrix()
		v = getValues()
		memTotal = unlist((v["mem.physmem"]))
		memTotal = unlist(lapply(memTotal, kbsToGb))
		memFree = unlist((v["mem.freemem"]))
		memFree = unlist(lapply(memFree, kbsToGb))
		memUsed = unlist((v["mem.util.used"]))
		memUsed = unlist(lapply(memUsed, kbsToGb))
		memCached = unlist((v["mem.util.cached"]))
		memCached = unlist(lapply(memCached, kbsToGb))
		memBuffer = unlist((v["mem.util.bufmem"]))
		memBuffer = unlist(lapply(memBuffer, kbsToGb))
		df <- data.frame(time = timeseries, mTotal = memTotal, mFree = memFree, mUsed = memUsed, mCached = memCached, mBuffer = memBuffer)
		p <- ggplot()  + geom_line(aes(time, mTotal, colour="memTotal"), df) + geom_line(aes(time, mFree, colour="memFree"), df) + geom_line(aes(time, mUsed, colour="memUsed"), df) + geom_line(aes(time, mCached, colour="memCached"), df) + geom_line(aes(time, mBuffer, colour="memBuffer"), df) + xlab("Time") + ylab("Memory (GB)") + theme(legend.title=element_blank()) + theme(legend.text = element_text(colour="blue", size = 16))
		print(p)
	})	


	output$plotXfsThroughput <- renderPlot({
		timeseries = getTimestamps()
		timeseries = timeseries[-1]
		stat = statMatrix()
		v = getValues()
		xfsReadbytes = unlist(diffList(v["xfs.read_bytes"]))
		xfsReadMb = unlist(lapply(xfsReadbytes, bytesToMb))
		xfsWritebytes = unlist(diffList(v["xfs.write_bytes"]))
		xfsWriteMb = unlist(lapply(xfsWritebytes, bytesToMb))
		df <- data.frame(time = timeseries, xfsRead = xfsReadMb, xfsWrite = xfsWriteMb) 
		p <-  ggplot()  + geom_line(aes(time, xfsRead , colour="xfsReadMb"), df) + geom_line(aes(time, xfsWrite, colour="xfsWriteMb"), df) +  xlab("Time") + ylab("Throughput (MB/s)") + theme(legend.title=element_blank()) + theme(legend.text = element_text(colour="blue", size = 16))
		print(p)
	})

	output$plotDiskThroughput <- renderPlot({
		timeseries = getTimestamps()
		timeseries = timeseries[-1]
		stat = statMatrix()
		v = getValues()
		diskReadbytes = unlist(diffList(v["disk.all.read_bytes"]))
		diskReadMb = unlist(lapply(diskReadbytes, bytesToMb))
		diskWritebytes = unlist(diffList(v["disk.all.write_bytes"]))
		diskWriteMb = unlist(lapply(diskWritebytes, bytesToMb))
		df <- data.frame(time = timeseries, diskRead = diskReadMb, diskWrite = diskWriteMb) 
		p <-  ggplot()  + geom_line(aes(time, diskRead, colour="diskReadMb"), df) + geom_line(aes(time, diskWrite, colour="diskWriteMb"), df) +  xlab("Time") + ylab("Throughput (MB/s)") + theme(legend.title=element_blank()) + theme(legend.text = element_text(colour="blue", size = 16))
		print(p)
	})
	

	output$view = renderPrint ({
		v = getValues()
		reads1 = v["mem.util.used"]
		x = unlist(reads1)
		x = lapply(x, kbsToGb)
		x = unlist(x)
		cat(x)
	})
})
