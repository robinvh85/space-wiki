# 
namespace :ico_tracking_price do
  task :start, [] => :environment do |_cmd, args|
    puts "Run rake ico_tracking_price:start"
    
    cycle_time = 15

    ico_account = IcoAccount.find(1)
    Bitfi.key = ico_account.key
    Bitfi.secret = ico_account.secret
    Bitfi.connect

    pair_list = ['SANUSD', 'LTCUSD', 'BCHUSD']
    cycle_time = 15
    index = 0

    while true
      start_time = Time.now

      pair_list.each do |pair_name|
        previous_price = nil
        period_type = '15s'

        price_obj = IcoTracking.save_price_log(pair_name, period_type, previous_price)
        previous_price = price_obj
        sleep(1)        
      end

      end_time = Time.now
      inteval = (end_time - start_time).to_i
      sleep(cycle_time - inteval) if cycle_time - inteval > 0
    end
  end
end

module IcoTracking
  class << self
    def save_price_log(pair_name, period_type, previous_price)
      price_obj = IcoTracking.get_price(pair_name)
      return price_obj if previous_price.nil?

      change_buy_percent = ((price_obj[:buy_price] - previous_price[:buy_price]) / previous_price[:buy_price] * 100).round(2)
      change_sell_percent = ((price_obj[:sell_price] - previous_price[:sell_price]) / previous_price[:sell_price] * 100).round(2)
      diff_price_percent = ((price_obj[:sell_price] - price_obj[:buy_price]) / price_obj[:buy_price] * 100).round(2)

      BtcPriceLog.create({
        pair_name: pair_name,
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

    def get_price(pair_name)
      @client = Bitfinex::Client.new
      @limit_amount = 0
      data = @client.orderbook(pair_name)
      
      buy_price = 0

      if data['bids'].nil?
        puts "CAN NOT GET PRICE !!!!!"
        return nil 
      end

      data['bids'].each do |bid|
        if bid["amount"].to_f > @limit_amount
          buy_price = bid["price"].to_f
          break
        end
      end

      sell_price = 0
      data['asks'].each do |ask|
        if ask["amount"].to_f > @limit_amount
          sell_price = ask["price"].to_f
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