module Ajax
  class OrdersController < ActionController::Base
    def index
      @pair = params[:pair]

      if @pair.nil? || @pair.empty?
        @pair = CurrencyPair.first.name
      end
      
      @currency_pairs = CurrencyPair.all
      @bid_orders = CurrentOrder.where(method: 'bid', currency_pair: @pair).select(:currency_pair, :method, :price, :amount, :total_price, :accumulate_price)
      @ask_orders = CurrentOrder.where(method: 'ask', currency_pair: @pair).select(:currency_pair, :method, :price, :amount, :total_price, :accumulate_price)

      render json: {
        bid_orders: @bid_orders,
        ask_orders: @ask_orders
      }
    end
  end
end