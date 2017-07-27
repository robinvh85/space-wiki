# 
namespace :tracking_btc do
  task :start, [] => :environment do |_cmd, args|
    puts "Run rake tracking_btc:get_price"
    
    cycle_time = 15

    while true
      puts "Get price of BTC at #{Time.now}"
      start_time = Time.now
      result = {}
      
      price_obj = TrackingBtc.get_price()

      ico_info = IcoInfo.find_by(currency_pair_name: "USDT_BTC")
      ico_info.current_buy_price = price_obj[:buy_price]
      ico_info.current_sell_price = price_obj[:sell_price]
      ico_info.save!

      end_time = Time.now
      inteval = (end_time - start_time).to_i

      sleep(cycle_time - inteval) if cycle_time - inteval > 0
    end
  end

  task :check_orders, [] => :environment do |_cmd, args|
    puts "Run rake tracking_btc:check_orders"

    cycle_time = 15
    while true
      start_time = Time.now

      TrackingBtc.check_orders()

      end_time = Time.now
      inteval = (end_time - start_time).to_i

      sleep(cycle_time - inteval) if cycle_time - inteval > 0
    end
  end

  task :log_price, [] => :environment do |_cmd, args|
    puts "Run rake tracking_btc:log_price"

    cycle_time_list = [10, 20, 30, 40]
    period_type_list = ['10s', '20s', '30s', '40s']
    
    threads = []
    thread_num = 4
    thread_num.times do |index|
      puts "Create thread #{index + 1}"
      thread = Thread.new{
        thread_id = index + 1
        cycle_time = cycle_time_list[index]
        previous_price = nil
        period_type = period_type_list[index]
        while true
          puts "Thread #{thread_id} - Write log at #{Time.now}"
          start_time = Time.now

          price_obj = TrackingBtc.save_price_log(period_type, previous_price)
          previous_price = price_obj

          end_time = Time.now
          inteval = (end_time - start_time).to_i

          sleep(cycle_time - inteval) if cycle_time - inteval > 0
        end
      }
    
      sleep(2)
      threads << thread
    end

    threads.each do |t|
      t.join
    end
  end
end

module TrackingBtc
  class << self
    def check_orders
      query = """
        (sell_order_id IS NOT NULL AND sold_order_id IS NULL) OR (buy_order_id IS NOT NULL AND bought_order_id IS NULL)
      """
      order_list = OrderBtc.where(query)

      order_list.each do |order|
        if !order.buy_order_id.nil? and order.bought_order_id.nil? # check buy order
          puts "Check buy order #{order.buy_order_id} at #{Time.now}"

          begin
            result = JSON.parse(`python script/python/check_trade_order.py #{order.buy_order_id}`)
            if result.present?
              order.bought_order_id = 1
              order.save
            end
          rescue
            puts "Buy order #{order.buy_order_id} is not existed!"
          end
        end
        
        if !order.sell_order_id.nil? and order.sold_order_id.nil?
          puts "Check sell order #{order.sell_order_id} at #{Time.now}"

          begin
            result = JSON.parse(`python script/python/check_trade_order.py #{order.sell_order_id}`)
            if result.present?
              order.sold_order_id = 1
              order.save
            end
          rescue
            puts "Sell order #{order.sell_order_id} is not existed!"
          end
        end
      end
    end

    def save_price_log(period_type, previous_price)
      price_obj = TrackingBtc.get_price()
      return price_obj if previous_price.nil?

      change_buy_percent = ((price_obj[:buy_price] - previous_price[:buy_price]) / previous_price[:buy_price] * 100).round(2)
      change_sell_percent = ((price_obj[:sell_price] - previous_price[:sell_price]) / previous_price[:sell_price] * 100).round(2)
      diff_price_percent = ((price_obj[:sell_price] - price_obj[:buy_price]) / price_obj[:buy_price] * 100).round(2)

      BtcPriceLog.create({
        buy_price: price_obj[:buy_price],
        sell_price: price_obj[:sell_price],
        change_buy_percent: change_buy_percent,
        change_sell_percent: change_sell_percent,
        diff_price_percent: diff_price_percent,
        period_type: period_type,
        time_at: Time.now.to_i
      })
      
      price_obj
    end

    def get_price
      pair_name = "USDT_BTC"
      response = PoloniexVh.order_book(pair_name)
      data = JSON.parse(response.body)

      limit_btc = 0.01
      buy_price = 0
      data['bids'].each do |bid|
        if bid[1].to_f > limit_btc
          buy_price = bid[0].to_f
          break
        end
      end

      sell_price = 0
      data['asks'].each do |ask|
        if ask[1].to_f > limit_btc
          sell_price = ask[0].to_f
          break
        end
      end

      {
        buy_price: buy_price,
        sell_price: sell_price
      }
    end
  end
end