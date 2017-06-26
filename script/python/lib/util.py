
import requests
from datetime import datetime

def logNow(msg=""):
	print "{0} : {1}".format(msg, datetime.now())

def getDatetimeNow(format="%Y-%m-%d %H:%M:%S"):
	return datetime.now().strftime(format)
	
def checkURL(url):
	result = 0
	r = requests.head(url)
	if r.status_code == 200:
		result = 1
	
	print "{0} => {1}".format(url, result)	
	return result