class PoloniexController < PoloniexBaseController

	def index
	end	

	def chart
		@currency_pairs = CurrencyPair.all.order(sort: 'asc')
	end

	def compare_chart
		@base_unit = params[:base_unit]
		@base_unit = 'USDT' if @base_unit.nil? || @base_unit.empty?

		@currency_pairs = CurrencyPair.where(base_unit: @base_unit, is_init: 1).order(sort: 'asc')
		@currency_pairs = @currency_pairs.to_a.unshift(CurrencyPair.find_by(name: 'USDT_BTC'))
	end

end
