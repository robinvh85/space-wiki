#### GHI CHU
# Can xac dinh gia tri chan lo hop ly. Dang thu nghiem 2%

# BotTradeInfo.status: -1: disabled, 0:ready, 1: running

namespace :ico_main do
  task :start_trading, [] => :environment do |_cmd, args|
    puts "Run rake ico:start_trading"
    
    threads = []

    3.times.each do |index|
      puts "Create thread #{index}"
      thread = Thread.new{
        while true
          puts "Find a new ICO at #{Time.now}"
          trade_info = BotTradeInfo.where("status = 0 AND priority > 0 AND percent_changed > 0").order(priority: 'DESC').first

          if trade_info.present?
            puts "Trading new #{trade_info.currency_pair_name}"
            trade_info.status = 1
            trade_info.save!

            currency_pair = CurrencyPair.find(trade_info.currency_pair_id)

            config = {
              currency_pair: currency_pair,
              buy_amount: trade_info.buy_amount,
              limit_invert_when_buy: trade_info.limit_invert_when_sell || 0.3,
              limit_invert_when_sell: trade_info.limit_invert_when_sell || 0.3,
              limit_good_profit: trade_info.limit_good_profit || 1.5,
              limit_losses_profit: trade_info.limit_losses_profit || 2,
              interval_time: trade_info.interval_time || 20,
              limit_verify_times: trade_info.limit_verify_times || 2,
              delay_time_after_sold: trade_info.delay_time_after_sold || 20,
              limit_pump_percent: 2,
              delay_time_when_pump: 30
            }  

            ico_obj = Ico.new(config)
            ico_obj.start_trading()

            trade_info.status = 0 # Set available for ico
            trade_info.save!
          end
          sleep(30)
        end
      }

      sleep(5)
      threads << thread
    end

    threads.each do |t|
      t.join
    end
  end

  task :reset_priority, [] => :environment do |_cmd, args|
    while true
      puts "Get Percent Changed at #{Time.now}"

      # Get percent changed
      BotTradeInfo.update_all(percent_changed: -100)
      result = JSON.parse(`python script/python/get_tickers.py`)
      result.each do |key, value|
        trade_info = BotTradeInfo.find_by(currency_pair_name: key)
        if trade_info.present?
          trade_info.percent_changed = value["percentChange"].to_f * 100
          trade_info.save!
        else
          puts "Have no pair #{key}"
        end

        ico_info = IcoInfo.find_by(currency_pair_name: key)
        if ico_info.present?
          ico_info.high_24hr = value["high24hr"]
          ico_info.low_24hr = value["low24hr"]
          ico_info.save!
        end
      end

      # Reset priority
      puts "Reset Priority at #{Time.now}"
      BotTradeInfo.update_all(priority: -100)
      sql = "SELECT currency_pair_id, currency_pair_name, created_at, SUM(profit) as profit 
        FROM bot_temp_trade_histories 
        WHERE trade_type = 'sell' AND DATE_SUB( NOW() , INTERVAL 1 HOUR ) < created_at GROUP BY profit 
        ORDER BY profit DESC
        LIMIT 10"

      list = BotTempTradeHistory.find_by_sql(sql)
      list.each do |item|
        trade_info = BotTradeInfo.find_by(currency_pair_id: item.currency_pair_id)
        trade_info.priority = item.profit
        trade_info.save
      end

      sleep(5 * 60)
    end
  end
end

PoloniexVh.setup do | config |
  config.key = 'VVGCGL9G-5YV2M7RC-TCTCYIFX-QBHGLPX6'
  config.secret = '0c4496e534e874a8533756ff5121f3e5be4add3c60b985157d9cf325a742c5c74fac18b1262667577c079809b084fa279110563911bcfdf75439588b858f8a59'
end

module Api
  class << self
    def get_current_trading_price(pair)
      result = {}
      response = PoloniexVh.order_book(pair.name)
      data = JSON.parse(response.body)

      {
        buy_price: data['bids'][0][0].to_f,
        sell_price: data['asks'][0][0].to_f
      }
    end

    def buy(pair, amount, price)
      puts "====> #{pair.name} Buy with Amount: #{amount} at Price: #{'%.8f' % price} at #{Time.now}"
      result = JSON.parse(`python script/python/buy.py #{pair.name} #{'%.8f' % (price * 1.01)} #{amount}`)
      trade = result["resultingTrades"][0]
      
      traded_amount = trade["amount"].to_f - trade["amount"].to_f * 0.005 # Remain 0.5%
      traded_price = trade["rate"].to_f

      puts "======> #{pair.name} BUY FINISH at price: #{'%.8f' % traded_price} - amount: #{traded_amount}"
      traded_price
    end

    def sell(pair, amount, price, bought_price)
      amount = amount - amount * 0.003
      price = price - price * 0.005 # remain 0.5%
      profit = (price - bought_price) / bought_price * 100

      puts "====> #{pair.name} Sell Amount: #{amount} with Price: #{'%.8f' % price}(#{profit.round(2)}%) at #{Time.now}"
      result = JSON.parse(`python script/python/sell.py #{pair.name} #{'%.8f' % price} #{amount}`)

      if result["resultingTrades"].length > 0
        trade = result["resultingTrades"][0]
        profit = (trade["rate"].to_f - bought_price) / bought_price * 100

        puts "=======> #{pair.name} SELL FINISH with Price: #{'%.8f' % price}(#{profit.round(2)}%) at #{Time.now}"
        true
      else
        false
      end
    end
  end
end
