import sys
import os.path
import MySQLdb

sys.path.append(os.path.abspath(os.path.join(os.path.dirname(__file__), "")))
import config
import util

def connect():
	global db
	global cursor
	
	if db == None:
		print "CONNECT TO MYSQL"
		db = MySQLdb.connect(config.DB_SERVER, config.DB_USER, config.DB_PASS, config.DB_NAME)
		cursor = db.cursor()

def executeNoneQuery(query):
	result = -1
	
	try:
		print query
		cursor.execute(query)	   
		db.commit()
		result = cursor.rowcount
	except Exception as e: 
		print(e)
		db.rollback()
		result = -1
	
	return result

def executeQueryFirst(query):
	result = None
	
	try:
		print query
		cursor.execute(query)	   
		result = cursor.fetchone()
	except Exception as e: 
		print(e)
	
	return result

def executeScalar(query):
	result = None
	
	try:
		print query
		cursor.execute(query)	   
		value = cursor.fetchone()
		result = value[0]
	except Exception as e: 
		print(e)
	
	return result
	
def executeQuery(query):
	result = []
	
	try:
		print query
		cursor.execute(query)	   
		result = cursor.fetchall()
	except Exception as e: 
		print(e)
	
	return result
	
def disconnect():
	global db
	global cursor

	db.close()
	cursor.close()
	
	db = None
	cursor = None
	
	print "DISCONNECT MYSQL"

######## MAIN ########	
db = None
cursor = None

