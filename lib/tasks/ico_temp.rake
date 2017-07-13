#### GHI CHU
# Can xac dinh gia tri chan lo hop ly. Dang thu nghiem 2%

# BotTradeInfo.status: -1: disabled, 0:ready, 1: running
# ico_temp
# + Su dung thread de chay training ico
# + Khuyet diem: chi start dc 4 thread chay dong thoi

namespace :ico_temp do
  task :start_trading, [] => :environment do |_cmd, args|
    puts "Run rake ico:start_trading temp"
    
    list = BotTradeInfo.where("status > -1") # Get all pair ready

    threads = []
    
    list.each do |pair|
      puts "Create thread for #{pair.currency_pair_name}"
      thread = Thread.new{
        currency_pair = CurrencyPair.find(pair.currency_pair_id)

        config = {
          currency_pair: currency_pair,
          buy_amount: pair.buy_amount,
          limit_invert_when_buy: pair.limit_invert_when_sell || 0.3,
          limit_invert_when_sell: pair.limit_invert_when_sell || 0.3,
          limit_good_profit: pair.limit_good_profit || 2,
          limit_losses_profit: pair.limit_losses_profit || 2,
          interval_time: pair.interval_time || 20,
          limit_verify_times: pair.limit_verify_times || 2,
          delay_time_after_sold: pair.delay_time_after_sold || 20,
          limit_pump_percent: 2,
          delay_time_when_pump: 30
        }  

        ico = TempIco.new(config)
        ico.start_trading()
      }

      sleep(3)
      threads << thread      
    end

    threads.each do |t|
      t.join
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
