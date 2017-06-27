module Ajax
  class OrdersController < ActionController::Base
    def index
      @pair = params[:pair]

      if @pair.nil? || @pair.empty?
        @pair = CurrencyPair.first.name
      end
      
      @currency_pairs = CurrencyPair.all
      data = Polo::Chart.get_current(@pair)

      render json: {
        bid_orders: data['bid_orders'],
        ask_orders: data['ask_orders']
      }
    end

    private    
  end
end