require 'bitfinex-api-rb'

namespace :bitfi_trade do
  task :save_ratio, [] => :environment do |_cmd, args|
    ico_pair_name = 'ZECUSD'
    btc_pair_name = 'BTCUSD'
    now = Time.now

    ico_price_log = BitfiPriceLog.where('pair_name = ? AND time_at < ?', ico_pair_name, now.to_i).order(id: 'desc').first
    btc_price_log = BitfiPriceLog.where('pair_name = ? AND time_at < ?', btc_pair_name, now.to_i).order(id: 'desc').first

    puts "Time: #{ico_price_log.created_at}"

    item = IcoRatio.create({
      pair_name: ico_price_log.pair_name,
      ratio: ((ico_price_log.buy_price / btc_price_log.buy_price) * 1000),
      ico_price: ico_price_log.buy_price,
      btc_price: btc_price_log.buy_price,
      time_at: btc_price_log.created_at
    })

    ico_bot = IcoBot.find(1)

    if ico_bot.trading_type == 'DONE'
      puts "Finding ICO for BUYING"
      # Check for buy
      now = Time.now
      hour_now = now - now.min.minutes - now.sec.seconds
      previous_time = time_now - 1.hours

      avg_ratio = IcoRatio.where('pair_name = ? AND time_at > ? AND time_at < ?', ico_pair_name, previous_time, hour_now).average(:ratio)

      diff = avg_ratio - item.ratio
      if diff > 0.5
        ico_bot.limit_price_for_buy = item.ico_price
        ico_bot.trading_type = 'BUYING'
      end
    end
  end
end
