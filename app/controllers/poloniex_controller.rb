class PoloniexController < PoloniexBaseController

	def index
	end	

	def chart
		@currency_pairs = CurrencyPair.all.order(sort: 'asc')
	end

	def compare_chart
		base_unit = params[:base_unit]
		base_unit = 'USDT' if base_unit.nil? || base_unit.empty?

		@currency_pairs = CurrencyPair.where(base_unit: base_unit, is_tracking: 1).order(sort: 'asc')
		@all_currency_pairs = CurrencyPair.where(base_unit: base_unit).order(sort: 'asc')
	end

end
