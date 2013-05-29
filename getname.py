#!/usr/bin/python

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

pmwebServer = config.get('PMWEB', 'pmwebServer')
pmwebPort = config.get('PMWEB', 'pmwebPort')

servers = []
s = config.options('SERVERS')
for i  in s:
	servers.append(config.get('SERVERS', i))

pmwebHandles = {}
for server in servers:
	pmwebHandles[server] = pmweb(pmwebServer, pmwebPort, server)

for server in servers:
	context =  pmwebHandles[server].getContext()
	name  =  pmwebHandles[server].getName(str(context), "network.interface.in.bytes")
	print name

