import urllib2
import json
import time
from pyelasticsearch import *
from pmweb import *
import ConfigParser
import sys
import os
import time

config = ConfigParser.ConfigParser()
config.read('rdat.cfg')

esServer = config.get('ELASTICSEARCH', 'esServer')
esServerPort = config.get('ELASTICSEARCH', 'esServerPort')

pmwebServer = config.get('PMWEB', 'pmwebServer')
pmwebPort = config.get('PMWEB', 'pmwebPort')

INDEX = config.get('ELASTICSEARCH', 'INDEX')
DOCTYPE = config.get('ELASTICSEARCH', 'DOCTYPE')

hostname = config.get('PCP', 'hostname')
kernelStats = config.get('PCP', 'kernelStats')
cpuStats = config.get('PCP','cpuStats')
memStats = config.get('PCP', 'memStats')
diskStats = config.get('PCP', 'diskStats')
xfsStats = config.get('PCP', 'xfsStats')

interval = float(config.get('RUNCONFIG', 'interval'))
stopfile = config.get('RUNCONFIG', 'stopfile')

esServer = "http://" + esServer + ":" + esServerPort + "/" 
print esServer
es = ElasticSearch(esServer)

stats = hostname + diskStats  + kernelStats + cpuStats + memStats + xfsStats

servers = []
s = config.options('SERVERS')
for i  in s:
	servers.append(config.get('SERVERS', i))

pmwebHandles = {}
for server in servers:
	pmwebHandles[server] = pmweb(pmwebServer, pmwebPort, server)

print pmwebHandles

cmd = "rm -rf " + stopfile
print cmd
os.system(cmd)

while(1):
	for server in servers:
		context =  pmwebHandles[server].getContext()
		stat = pmwebHandles[server].getStats(str(context), stats)
		stat["hostname"] = server
		print stat
		es.index(INDEX, DOCTYPE, stat)

	if (os.path.exists(stopfile)):
		sys.exit(0)
	
	time.sleep(interval)	
