import urllib2
import json

class pmweb:
	def __init__(self, host, port, server):
		self.host = host
		self.port = port
		self.server = server

	def getContext(self):
		url = "http://" + self.host + ":" + str(self.port) + "/pmapi/context?" + "hostname=" + self.server
		print  url
		response = urllib2.urlopen(url)
		res = response.read()
		res = json.loads(res)
		return res["context"]
	
	def getStats(self, context, stats):
		url = "http://" + self.host + ":" + str(self.port) + "/pmapi/" + context + "/_fetch?names=" + stats 
		print  url
		response = urllib2.urlopen(url)
		res = response.read()
		res = json.loads(res)
		return res
		pass
