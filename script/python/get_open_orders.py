import poloniex
import json

def main():
	global polo

	value = polo.returnOpenOrders()
	print json.dumps(value)
	
	
######  MAIN  ######
polo = poloniex.Poloniex('VVGCGL9G-5YV2M7RC-TCTCYIFX-QBHGLPX6','0c4496e534e874a8533756ff5121f3e5be4add3c60b985157d9cf325a742c5c74fac18b1262667577c079809b084fa279110563911bcfdf75439588b858f8a59')
main()