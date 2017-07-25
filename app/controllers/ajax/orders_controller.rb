module Ajax
  class OrdersController < ActionController::Base
    def index
      @pair = params[:pair]

      if @pair.nil? || @pair.empty?
        @pair = 'USDT_BTC'
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
      OpenOrder.where(is_old: 0).update_all(is_old: 1)
      
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
      
      old_orders = OpenOrder.where(is_old: 1)
      old_orders.each do |order|
        order.is_old = 2
        order.save 
      end

      render json: {
        open_orders: OpenOrder.where(is_old: 0)
      }
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

      if result['success'] == 1
        OpenOrder.find_by(order_number: params['order_number']).delete()
      end

      render json: {
        success: result['success']
      }
    end

    def done
      trade_id = params['trade_id']

      model = TradeHistory.find_by(trade_id: trade_id)
      model.is_sold = 1
      model.save

      render json: {
        status: 'OK'
      }
    end

    def get_history_trade
      list = JSON.parse(`python script/python/get_trade_history.py #{(Time.now.to_i - 1.day).to_i} #{Time.now.to_i}`)

      list.each do |pair, pair_item|
        obj_pair = CurrencyPair.find_by(name: pair)

        pair_item.each do |item|
          if TradeHistory.find_by(trade_id: item['tradeID']).nil?
            item = {
              category: item['category'],
              fee:      item['fee'],
              trade_id: item['tradeID'],
              order_number: item['orderNumber'],
              amount:   item['amount'],
              rate:     item['rate'],
              date_time: item['date'],
              total:    item['total'],
              trade_type: item['type'],
              currency_pair_id: obj_pair.id,
              currency_pair_name: obj_pair.name
            }
            
            TradeHistory.create(item)
          end
        end
      end

      render json: {
        status: 'OK'
      }
    end

    def get_history_trading
      list = TradeHistory.where("trade_type='buy' AND is_sold=0")
      
      render json: list
    end

    def get_open_order_btc
      list = OrderBtc.all
      
      render json: list
    end

    private    
  end
end