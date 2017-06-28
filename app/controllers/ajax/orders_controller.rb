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
      OpenOrder.update_all(is_old: 1)
      
      orders.each do |key, values|
        if values.length > 0
          data[key] = values
          pair = CurrencyPair.find_by(name: key)
          
          values.each do |value|
            open_order = OpenOrder.find_by(order_number: value['orderNumber'])
            if open_order.nil?
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
            else
              open_order.is_old = 0;
              open_order.save
            end                      
          end
        end
      end
      
      OpenOrder.where(is_old: 1).delete_all

      render json: OpenOrder.all
    end

    def get_current_price
      pair = params[:pair]
      data = Polo::Chart.get_current(pair)

      render json: {
        buy_price: data['bid_orders'][0],
        sell_price: data['ask_orders'][0]
      }
    end

    def update_buy_price
      order_number = params['order_number']
      buy_price = params['buy_price']

      model = OpenOrder.find_by(order_number: order_number)
      model.buy_price = buy_price
      model.save

      render json: {
        status: 'OK'
      }
    end

    def cancel
      result = JSON.parse(`python script/python/cancel_order.py #{params['order_number']}`)

      render json: {
        success: result['success']
      }
    end

    private    
  end
end