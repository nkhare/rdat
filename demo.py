import urllib2
import json
import time
from pyelasticsearch import *

INDEX = 'pcp'
DOCTYPE = 'PS'

class pmweb:
	def __init__(self, host, port, server):
		self.host = host
		self.port = port
		self.server = server

	def getContext(self):
		print self.host
		url = "http://" + self.host + ":" + str(self.port) + "/pmapi/context?" + "hostname=" + self.server
		print  url
		response = urllib2.urlopen(url)
		res = response.read()
		res = json.loads(res)
		return res["context"]
	
	def	getStats(self, context, stats):
		url = "http://" + self.host + ":" + str(self.port) + "/pmapi/" + context + "/_fetch?names=" + stats 
		print  url
		response = urllib2.urlopen(url)
		res = response.read()
		res = json.loads(res)
		return res
		pass


h1 = pmweb("localhost", 44323, "gprfs016.sbu.lab.eng.bos.redhat.com")
count = 0
while (count < 10) :
	context = h1.getContext()
	hostname = "kernel.uname.nodename"
	kernelStats = ",kernel.all.load,kernel.all.intr,kernel.all.runnable,kernel.all.nprocs"
	cpuStats =  ",kernel.all.cpu.user,kernel.all.cpu.nice,kernel.all.cpu.sys,kernel.all.cpu.idle,kernel.all.cpu.intr"
	memStats = ",mem.physmem,mem.freemem,mem.util.used,mem.util.free,mem.util.shared,mem.util.bufmem,mem.util.cached"
	diskStats = ",disk.all.read,disk.all.write,disk.all.read_bytes,disk.all.write_bytes,disk.all.aveq"
	xfsStats = ",xfs.write,xfs.write_bytes,xfs.read,xfs.read_bytes"

	stats = hostname + diskStats  #+ kernelStats + cpuStats + diskStats + xfsStats
	stat = h1.getStats(str(context), stats)
	print type(stat)
	stat["hostname"] = "gprfs016.sbu.lab.eng.bos.redhat.com"
	doc = stat
	print doc
	es = ElasticSearch('http://perf19:9200/')
	es.index(INDEX, DOCTYPE, doc)
	count = count + 1
	time.sleep(4)
