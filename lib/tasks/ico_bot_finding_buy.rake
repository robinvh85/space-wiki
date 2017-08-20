
namespace :ico_bot_finding_buy do
  task :start, [] => :environment do |_cmd, args|
    puts "Run rake ico_bot_finding_buy:start"
    
    pair_name = 'BCHUSD'
    url = "https://api.bitfinex.com/v2/candles/trade:5m:t#{pair_name}/hist?limit=2"

    while true
      sleep(20)
      puts "#{pair_name} - Find buy price at #{Time.now}"
      bot = IcoBot.find_by(pair_name: pair_name)
      next if bot.trading_type != 'DONE'

      ico_price = IcoPriceLog.where(pair_name: pair_name).last
      puts "#{pair_name} - change percent: #{ico_price.change_buy_percent}"
      next if ico_price.change_buy_percent < 1

      candles = JSON.parse(`curl #{url}`)
      candles[-1]

      previous_candle = {
        open: candles[-1][1],
        close: candles[-1][2],
        high: candles[-1][3],
        low: candles[-1][4],
      }

      if previous_candle[:close] < previous_candle[:open] # If down
        puts "#{pair_name} - set BUY with percent #{ico_price.change_buy_percent}"
        bot.trading_type = 'FORCE_BUY'
        bot.status = 1
        bot.buy_price = bot.current_buy_price + bot.current_buy_price * 0.003
        bot.sell_price = bot.buy_price + bot.buy_price * 0.05
        bot.save!
      end
    end  
  end
end
