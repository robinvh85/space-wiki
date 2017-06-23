class PoloniexController < PoloniexBaseController

	def index
	end	

	def chart
		@currency_pairs = CurrencyPair.all
	end

end
