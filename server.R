library(shiny)
library(RCurl)
library(rjson)
library(datasets)
library(ggplot2)
library(dataframes2xls)

# Define server logic required to summarize and view the selected dataset
shinyServer(function(input, output) {

        # Return the requested dataset
	Data <- reactive(function() {
		host1 = input$host
		elasticServer = input$esServer 
		elasticPort = input$esServerPort
		index = input$esIndex
		nic = as.integer(input$nic)
 		url=paste0("http://",elasticServer,":",elasticPort,"/",index,"/","/_search?source={%22size%22:3600,%22query%22:{%22bool%22:{%22must%22:[{%22term%22:{%22PS.hostname%22:%22",host1,"%22}}]}},%22sort%22:[{%22timestamp.s%22:{%22order%22:%22asc%22}}]}")
		raw=getURL(url)
		data=fromJSON(raw)
		hits=data$hits$hits
		timestamps = sapply(hits, gettimestamp)
		time = as.POSIXct(timestamps, origin="1970-01-01","%H:%M:%S")

		names = sapply(hits[[1]]$"_source"$values, getname)
		namesCount =  (length(names))

		values = list()
		for (i in 1:namesCount) {
		  v = sapply(hits, getval, i) 
		  values[[names[i]]] = list(v)
		}

		instanceCount = list()
		for (i in 1:namesCount) {
		  count = getinstanceCount(hits[[1]], i) 
		  instanceCount[[names[i]]] = count
		}
	
		info = list(time = time, values = values, instanceCount = instanceCount, nic = nic)
	})

	source('util.R')

	
	output$plotDisk <- reactivePlot( function(){
		timeseries = Data()$time
		timeseries = timeseries[-1]
		v <- Data()$values
		reads = v["disk.all.read"]
		reads = diffList(reads)
		reads = unlist(reads)
		writes = v["disk.all.write"]
		writes = diffList(writes)
		writes = unlist(writes)
		df <- data.frame(time = timeseries, readsIops = reads, writeIops = writes)
#		write.csv(df, "/tmp/iops.csv")
#		write.xls(df, "/tmp/iops.xls")
		p <-  ggplot() + geom_line(aes(time, readsIops, colour="reads"), df) + geom_line(aes(time, writeIops, colour="writes"), df) + xlab("Time") + ylab("IOPS") + theme(legend.title=element_blank()) + theme(legend.text = element_text(colour="blue", size = 16)) + opts(title = "Disk IOPS")  
		print(p)
		})

	output$plotXfsIops <- reactivePlot( function(){
		timeseries = Data()$time
		timeseries = timeseries[-1]
		v <- Data()$values
		xfsReads = unlist(diffList(v["xfs.read"]))
		xfsWrites = unlist(diffList(v["xfs.write"]))
		xfsReadbytes = unlist(diffList(v["xfs.read_bytes"]))
		xfsWritebytes = unlist(diffList(v["xfs.write_bytes"]))
		xfsLogWrites = unlist(diffList(v["xfs.log.writes"]))
		xfsIflush = unlist(diffList(v["xfs.iflush_count"]))
		df <- data.frame(time = timeseries, readsIops = xfsReads, writeIops = xfsWrites, logWriteIops = xfsLogWrites,  xfsIflushCount = xfsIflush )
#		write.csv(df, "/tmp/xfs.csv")
		p <-  ggplot() + geom_line(aes(time, readsIops, colour="xfsReads"), df) + geom_line(aes(time, writeIops, colour="xfsWrites"), df) + geom_line(aes(time, logWriteIops, colour="xfsLogWrites"), df) +  geom_line(aes(time, xfsIflushCount, colour="xfsIflush"), df) + xlab("Time") + ylab("XFS IOPS") + theme(legend.title=element_blank()) + theme(legend.text = element_text(colour="blue", size = 16)) + opts(title = "XFS IOPS")  
		print(p)

	})
	output$plotXfsAttr <- reactivePlot( function(){
		timeseries = Data()$time
		timeseries = timeseries[-1]
		v <- Data()$values
		xfsSetattr = unlist(diffList(v["xfs.attr.set"]))
		xfsGetattr = unlist(diffList(v["xfs.attr.get"]))
		df <- data.frame(time = timeseries, xfsSetattrCount = xfsSetattr, xfsGetattrCount = xfsGetattr)
		p <-  ggplot()  + geom_line(aes(time, xfsSetattrCount , colour="xfsSetattr"), df) + geom_line(aes(time, xfsGetattrCount, colour="xfsGetattr"), df) + xlab("Time") + ylab("XFS Xattr OP Count") + theme(legend.title=element_blank()) + theme(legend.text = element_text(colour="blue", size = 16)) + opts(title = "XFS Set/Get Xattr stats")  
		print(p)

	})
	

	output$plotCpu <- reactivePlot( function(){
		timeseries = Data()$time
		timeseries = timeseries[-1]
		v <- Data()$values
		cpuUser = unlist(diffList(v["kernel.all.cpu.user"]))
		cpuNice = unlist(diffList(v["kernel.all.cpu.nice"]))
		cpuSys = unlist(diffList(v["kernel.all.cpu.sys"]))
		cpuIdle = unlist(diffList(v["kernel.all.cpu.idle"]))
		cpuIntr = unlist(diffList(v["kernel.all.cpu.intr"]))
		df <- data.frame(time = timeseries, user = cpuUser, nice = cpuNice, sys = cpuSys, idle = cpuIdle, intr = cpuIntr )#, nice = CpuNice)
		p <- ggplot() + geom_line(aes(time, user, colour="user"), df) + geom_line(aes(time, nice, colour="nice"), df) + geom_line(aes(time, sys, colour="sys"), df) + geom_line(aes(time, idle, colour="idle"), df) + geom_line(aes(time, intr, colour="intr"), df) +  xlab("Time") + ylab("CPU Usage") + theme(legend.title=element_blank()) + theme(legend.text = element_text(colour="blue", size = 16)) + opts(title="CPU") + opts(title = "CPU stats")  

		print(p)
	})
	output$plotMemory <- reactivePlot( function(){
		timeseries = Data()$time
		v <- Data()$values
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
		p <- ggplot()  + geom_line(aes(time, mTotal, colour="memTotal"), df) + geom_line(aes(time, mFree, colour="memFree"), df) + geom_line(aes(time, mUsed, colour="memUsed"), df) + geom_line(aes(time, mCached, colour="memCached"), df) + geom_line(aes(time, mBuffer, colour="memBuffer"), df) + xlab("Time") + ylab("Memory (GB)") + theme(legend.title=element_blank()) + theme(legend.text = element_text(colour="blue", size = 16)) + opts(title = "Memory Stats") 
		print(p)
	})	
	output$plotXfsThroughput <- reactivePlot( function(){
		timeseries = Data()$time
		timeseries = timeseries[-1]
		v <- Data()$values
		xfsReadbytes = unlist(diffList(v["xfs.read_bytes"]))
		xfsReadMb = unlist(lapply(xfsReadbytes, bytesToMb))
		xfsWritebytes = unlist(diffList(v["xfs.write_bytes"]))
		xfsWriteMb = unlist(lapply(xfsWritebytes, bytesToMb))
		df <- data.frame(time = timeseries, xfsRead = xfsReadMb, xfsWrite = xfsWriteMb) 
		p <-  ggplot()  + geom_line(aes(time, xfsRead , colour="xfsReadMb"), df) + geom_line(aes(time, xfsWrite, colour="xfsWriteMb"), df) +  xlab("Time") + ylab("Throughput (MB/s)") + theme(legend.title=element_blank()) + theme(legend.text = element_text(colour="blue", size = 16)) + opts(title = "XFS Throughput")  
		print(p)
	})

	output$plotDiskThroughput <- reactivePlot( function(){
		timeseries = Data()$time
		timeseries = timeseries[-1]
		v <- Data()$values
		diskReadbytes = unlist(diffList(v["disk.all.read_bytes"]))
		diskReadMb = unlist(lapply(diskReadbytes, kbsToMb))
		diskWritebytes = unlist(diffList(v["disk.all.write_bytes"]))
		diskWriteMb = unlist(lapply(diskWritebytes, kbsToMb))
		df <- data.frame(time = timeseries, diskRead = diskReadMb, diskWrite = diskWriteMb) 
#		write.csv(df, "/tmp/throughput.csv")
		p <-  ggplot()  + geom_line(aes(time, diskRead, colour="diskReadMb"), df) + geom_line(aes(time, diskWrite, colour="diskWriteMb"), df) +  xlab("Time") + ylab("Throughput (MB/s)") + theme(legend.title=element_blank()) + theme(legend.text = element_text(colour="blue", size = 16)) + opts(title = "Disk Throughput")
		print(p)
	})
	

	output$plotNetwork <- renderPlot({
		#timeseries = getTimestamps()
		timeseries = Data()$time
		timeseries = timeseries[-1]
		v <- Data()$values
		instanceCounts = Data()$instanceCount
		nic = Data()$nic
		rows = instanceCounts["network.interface.in.bytes"]
		rows = rows[[1]]
		reads = v["network.interface.in.bytes"]
		writes = v["network.interface.out.bytes"]
		reads = reads[[1]]
		writes = writes[[1]]
		reads = matrix(unlist(reads), nrow = rows)
		writes = matrix(unlist(writes), nrow = rows)
		df <- data.frame(time = timeseries, readsIops = unlist(diffList(reads[nic,])), writeIops = unlist(diffList(writes[nic,])))
		write.csv(df, "/tmp/iops.csv")
		p <-  ggplot() + geom_line(aes(time, readsIops, colour="in bytes"), df) + geom_line(aes(time, writeIops, colour="Out bytes"), df) + xlab("Time") + ylab("bytes per sec") + theme(legend.title=element_blank()) + theme(legend.text = element_text(colour="blue", size = 16)) + opts(title = "Network")  
#		p <- ggplot() + geom_line(aes(y = writeIops, x = readsIops, colour="reads"), df)
		print(p)
		})

	output$view = renderPrint ({
		v = Data()$values
		reads = v["network.interface.in.bytes"]
		writes = v["network.interface.out.bytes"]
		reads = reads[[1]]
		writes = writes[[1]]
		reads = unlist(reads)
		writes = unlist(writes)
		reads = matrix(reads, nrow = 5)
		writes = matrix(writes, nrow = 5)
		print(Data()$instanceCount)
		instanceCounts = Data()$instanceCount
		rows = instanceCounts["network.interface.in.bytes"]
		print(rows[[1]])
		nic = Data()$nic
		print(nic)
		#r = diffList(writes[2,])
		#r
	})
})
