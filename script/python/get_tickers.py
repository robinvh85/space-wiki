import poloniex
import json

def main():
	global polo

	value = polo.returnTicker()
	print json.dumps(value)
	
	
######  MAIN  ######
polo = poloniex.Poloniex()
main()