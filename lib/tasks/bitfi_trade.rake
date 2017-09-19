require 'bitfinex-api-rb'

namespace :bitfi_trade do
  task :save_ratio, [] => :environment do |_cmd, args|
    puts 'Run bitfi_trade:save_ratio'

    ico_pair_name = 'BCHUSD'
    btc_pair_name = 'BTCUSD'
    now = Time.now
    diff_ratio = 0

    ico_price_log = BitfiPriceLog.where('pair_name = ? AND time_at < ?', ico_pair_name, now.to_i).order(id: 'desc').first
    btc_price_log = BitfiPriceLog.where('pair_name = ? AND time_at < ?', btc_pair_name, now.to_i).order(id: 'desc').first
    ratio = ((ico_price_log.buy_price / btc_price_log.buy_price) * 1000)

    now = Time.now
    hour_now = now - now.min.minutes - now.sec.seconds
    previous_time = hour_now - 1.hours

    avg_ratio = IcoRatio.where('pair_name = ? AND time_at > ? AND time_at < ?', ico_pair_name, previous_time, hour_now).average(:ratio)
    unless avg_ratio.nil?
      diff_ratio = avg_ratio - ratio
    end

    ico_ratio = IcoRatio.create({
      pair_name: ico_price_log.pair_name,
      ratio: ratio,
      diff_ratio: diff_ratio,
      ico_price: ico_price_log.buy_price,
      btc_price: btc_price_log.buy_price,
      time_at: btc_price_log.created_at
    })

    ico_bot = IcoBot.find(1)

    if ico_bot.trading_type == 'DONE'
      # Check for buy
      unless avg_ratio.nil?
        puts "Finding ICO for BUYING at #{Time.now} with diff #{diff_ratio}"
        if diff_ratio > 0.5
          ico_bot.limit_price_for_buy = ico_ratio.ico_price
          ico_bot.trading_type = 'BUYING'
          ico_bot.save
        end
      end
    end
  end
end
