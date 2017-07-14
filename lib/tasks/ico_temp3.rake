#### GHI CHU
# Can xac dinh gia tri chan lo hop ly. Dang thu nghiem 2%
# BotTradeInfo.status: -1: disabled, 0:ready, 1: running
# ico_temp3:
# + Chay training toi da 15 ico
# + Chi chay training nhung ico co percentChange > 0

namespace :ico_temp3 do
  task :start_trading, [] => :environment do |_cmd, args|
    puts "Run rake ico:start_trading temp"
    

    ico_list = []
    inteval = 20

    while true
      # Get 1 trade_info best and save ico to ico_list
      # ico_list max length is 15
      puts "ico_list.length is #{ico_list.length}. Check for new TradeInfo at #{Time.now}"
      if ico_list.length < 15
        trade_info = BotTradeInfo.where("temp_status = 0 AND percent_changed > 0").order(percent_changed: 'DESC').first

        if trade_info.present?
          puts "Start training for #{trade_info.currency_pair_id}"

          currency_pair = CurrencyPair.find(trade_info.currency_pair_id)

          config = {
            currency_pair: currency_pair,
            buy_amount: trade_info.buy_amount,
            limit_invert_when_buy: trade_info.limit_invert_when_sell || 0.3,
            limit_invert_when_sell: trade_info.limit_invert_when_sell || 0.3,
            limit_good_profit: trade_info.limit_good_profit || 2,
            limit_losses_profit: trade_info.limit_losses_profit || 2,
            interval_time: trade_info.interval_time || 20,
            limit_verify_times: trade_info.limit_verify_times || 2,
            delay_time_after_sold: trade_info.delay_time_after_sold || 20,
            limit_pump_percent: 2,
            delay_time_when_pump: 30
          }  

          ico = TempIco.new(config)
          ico_list << ico
          trade_info.temp_status = 1
          trade_info.save
        end
      end

      # Chay training nhung ico nam trong list
      ico_list.each do |ico|
        puts "Training #{ico.currency_pair.name}"
        ico.update_current_price()
        ico.analysis()
        
        if ico.is_sold == true # when end of a trade cycle
          trade_info = BotTradeInfo.find_by(currency_pair_id: ico.currency_pair.id)
          trade_info.temp_status = 0
          ico_list.delete(ico)
        end

        sleep(0.01)
      end

      time_sleep = inteval
      time_sleep = inteval/ico_list.length if ico_list.length > 0

      sleep(time_sleep)
    end
  end
end

PoloniexVh.setup do | config |
  config.key = 'VVGCGL9G-5YV2M7RC-TCTCYIFX-QBHGLPX6'
  config.secret = '0c4496e534e874a8533756ff5121f3e5be4add3c60b985157d9cf325a742c5c74fac18b1262667577c079809b084fa279110563911bcfdf75439588b858f8a59'
end

module ApiTemp
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
      # result = JSON.parse(`python script/python/buy.py #{pair.name} #{'%.8f' % (price * 1.01)} #{amount}`)
      # trade = result["resultingTrades"][0]
      sleep(2) # time to buy
            
      traded_amount = amount
      traded_price = price

      puts "======> #{pair.name} BUY FINISH at price: #{'%.8f' % traded_price} - amount: #{traded_amount}"
      traded_price
    end

    def sell(pair, amount, price, bought_price)
      amount = amount - amount * 0.003
      price = price - price * 0.005 # remain 0.5%
      profit = (price - bought_price) / bought_price * 100

      puts "====> #{pair.name} Sell Amount: #{amount} with Price: #{'%.8f' % price}(#{profit.round(2)}%) at #{Time.now}"
      # result = JSON.parse(`python script/python/sell.py #{pair.name} #{'%.8f' % price} #{amount}`)
      sleep(2) # time to sell

      # trade = result["resultingTrades"][0]
      # profit = (trade["rate"].to_f - bought_price) / bought_price * 100
      profit = (price - bought_price) / bought_price * 100

      puts "=======> #{pair.name} SELL FINISH with Price: #{'%.8f' % price}(#{profit.round(2)}%) at #{Time.now}"
      true
    end

  end
end
