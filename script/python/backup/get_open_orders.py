# yum install MySQL-python

######################
# 1. Check is_available for Approved products
######################

import sys
import os.path
import poloniex

sys.path.append(os.path.abspath(os.path.join(os.path.dirname(__file__), "lib")))
import config
import util
import mysql


def saveOpenOrders(data):
	query = """
		INSERT INTO open_orders(order_number, margin, amount, price, total, starting_amount, date_time)
		VALUES('{0}', {1}, {2}, {3}, {4}, {5}, {6})
	""".format(config.TABLE_PRODUCT, data[0], data[1], data[2], data[3], data[4], data[5], data[6])
	
	mysql.executeNoneQuery(query)

def getOpenOrders():
	global polo
	print "RUN : getOpenOrders()"
	data = polo.returnOpenOrders()
	


def updateIsAvailable():
	print "RUN : updateIsAvailable()"

	query = """
		SELECT id, url_source, is_available FROM {0}
		WHERE status = 'Approved'
	""".format(config.TABLE_PRODUCT)
	
	try: 
		results = mysql.executeQuery(query)
		for row in results:
			status = util.checkURL(row[1])
			
			if status != row[2]:
				setAvailable(row[0], status)
			
	except Exception as e: 
		print(e)
		
		
def main():
	saveOpenOrders()
	
	
######  MAIN  ######
print "\n=========== RUN get_open_orders.py ============"
mysql.connect()
polo = poloniex.Poloniex('VVGCGL9G-5YV2M7RC-TCTCYIFX-QBHGLPX6','0c4496e534e874a8533756ff5121f3e5be4add3c60b985157d9cf325a742c5c74fac18b1262667577c079809b084fa279110563911bcfdf75439588b858f8a59')

util.logNow("START AT")
main()
util.logNow("END AT")

mysql.disconnect()