class PoloniexController < PoloniexBaseController

	def index
	end	

	def chart
		@currency_pairs = CurrencyPair.all
	end

	def compare_chart
		@currency_pairs = CurrencyPair.where(is_init: 1)
	end

end
