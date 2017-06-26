class PoloniexController < PoloniexBaseController

	def index
	end	

	def chart
		@currency_pairs = CurrencyPair.all.order(sort: 'asc')
	end

	def compare_chart
		@currency_pairs = CurrencyPair.where(is_init: 1).order(sort: 'asc')
	end

end
