import urllib2
import json
import time
from pyelasticsearch import *

INDEX = 'pcp'
DOCTYPE = 'PS'

class pmweb:
	def __init__(self, host, port):
		self.host = host
		self.port = port

	def getContext(self):
		print self.host
		url = "http://" + self.host + ":" + str(self.port) + "/pmapi/context?" + "hostname=" + "perf19"
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


h1 = pmweb("localhost", 44323)
count = 0
while (count < 10) :
	context = h1.getContext()
	stats = "kernel.uname.nodename,kernel.all.load,mem.util.used,kernel.all.cpu.sys,disk.all.write,disk.all.read" 
	#stats = "disk.dev.read,disk.dev.write"
	stat = h1.getStats(str(context), stats)
	doc = stat
	print doc
	es = ElasticSearch('http://perf19:9200/')
	es.index(INDEX, DOCTYPE, doc)
	count = count + 1
	time.sleep(4)
