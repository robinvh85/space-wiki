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

    def get_open_orders
      orders = JSON.parse(`python script/python/get_open_orders.py`)
      data = {}
      OpenOrder.delete_all
      orders.each do |key, values|
        if values.length > 0
          data[key] = values
          pair = CurrencyPair.find_by(name: key)
          
          values.each do |value|           
            OpenOrder.create({
              currency_pair_id: pair.id,
              currency_pair_name: pair.name,
              order_number: value['orderNumber'],
              margin: value['margin'],
              amount: value['amount'],
              price: value['rate'],
              date_time: value['date'],
              total: value['total'],
              order_type: value['type'],
              starting_amount: value['startingAmount']
            })
          end
        end
      end
      
      render json: OpenOrder.all
    end

    private    
  end
end