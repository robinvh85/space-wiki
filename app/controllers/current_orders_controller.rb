class CurrentOrdersController < PoloniexBaseController
	# before_action :authenticate_user!	

	def index
		@pair = params[:pair]

		if @pair.nil?
			@pair = CurrencyPair.first.name
		end
		
		@currency_pairs = CurrencyPair.all
		@bid_orders = CurrentOrder.where(method: 'bid', currency_pair: @pair)
		@ask_orders = CurrentOrder.where(method: 'ask', currency_pair: @pair)
	end
end
