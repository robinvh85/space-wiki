class PoloniexController < PoloniexBaseController

	def index
	end	

	def analysis
		@base_unit = params[:base_unit]
		@base_unit = 'BTC' if @base_unit.nil? || @base_unit.empty?

		@currency_pairs = CurrencyPair.all.order(sort: 'asc')
		@all_currency_pairs = CurrencyPair.where(base_unit: @base_unit).order(percent_min_24h: 'asc')
	end

	def analysisavg
		@base_unit = params[:base_unit]
		@base_unit = 'BTC' if @base_unit.nil? || @base_unit.empty?

		@currency_pairs = CurrencyPair.all.order(sort: 'asc')
		@all_currency_pairs = CurrencyPair.where(base_unit: @base_unit).order(sort: 'asc')
	end

	def chart
		@currency_pairs = CurrencyPair.all.order(sort: 'asc')
	end

	def compare_chart
		@base_unit = params[:base_unit]
		@all = params[:all]
		@base_unit = 'BTC' if @base_unit.nil? || @base_unit.empty?

		if @all.nil? || @all.empty?
			@currency_pairs = CurrencyPair.where(base_unit: @base_unit, is_tracking: 1).order(sort: 'asc')
		else
			@currency_pairs = CurrencyPair.where(base_unit: @base_unit).order(sort: 'asc')
		end

		@currency_pairs = @currency_pairs.to_a.unshift(CurrencyPair.find_by(name: 'USDT_BTC')) if @base_unit == 'BTC'
		@all_currency_pairs = CurrencyPair.where(base_unit: @base_unit).order(sort: 'asc')
	end

	def realtime
	end
	
end
