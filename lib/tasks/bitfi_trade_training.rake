require 'bitfinex-api-rb'

namespace :bitfi_trade_training do
  task :buy, [:price] => :environment do |_cmd, args|
    api_obj = nil
    acc = IcoAccount.first
    if acc.site == 'Bitfi'
      api_obj = Bitfi.new({
        key: acc.key,
        secret: acc.secret
      })
    end

    pair_name = 'BCHUSD'
    amount_usd = 50.0
    # buy_price = 371
    buy_price = args[:price].to_f
    buy_amount = (amount_usd / buy_price).round(8)
    puts "Buy with amount #{buy_amount}"
    api_obj.buy(pair_name, buy_amount, buy_price)
  end

  task :sell, [:price] => :environment do |_cmd, args|
    api_obj = nil
    acc = IcoAccount.first
    if acc.site == 'Bitfi'
      api_obj = Bitfi.new({
        key: acc.key,
        secret: acc.secret
      })
    end

    pair_name = 'BCHUSD'
    # sell_price = 374
    sell_price = args[:price]
    # amount = 0.1347
    amount = api_obj.get_balances('bch')
    puts "Sell with amount #{amount}"
    api_obj.sell(pair_name, amount, sell_price)
  end

  task :check_price, [] => :environment do |_cmd, args|
    api_obj = nil
    acc = IcoAccount.first
    if acc.site == 'Bitfi'
      api_obj = Bitfi.new({
        key: acc.key,
        secret: acc.secret
      })
    end
    pair_name = 'BCHUSD'
    while true
      data = api_obj.get_current_trading_price(pair_name, 0)
      puts "Price #{data.to_json}"
      sleep(20)
    end
  end

  task :ratio, [] => :environment do |_cmd, args|
    ico_pair_name = 'ZECUSD'
    btc_pair_name = 'BTCUSD'
    from_time_str = '2017-09-14 16:20:21'
    from_time = Time.parse(from_time_str)
    now = Time.now

    while from_time < now
      ico_price_log = BitfiPriceLog.where('pair_name = ? AND time_at > ?', ico_pair_name, from_time.to_i).first
      btc_price_log = BitfiPriceLog.where('pair_name = ? AND time_at > ?', btc_pair_name, from_time.to_i).first

      puts "Time: #{ico_price_log.created_at}"

      IcoRatio.create({
        pair_name: ico_price_log.pair_name,
        ratio: ((ico_price_log.buy_price / btc_price_log.buy_price) * 1000),
        ico_price: ico_price_log.buy_price,
        btc_price: btc_price_log.buy_price,
        time_at: btc_price_log.created_at
      })

      from_time += 5.minutes
    end
  end

  task :training, [] => :environment do |_cmd, args|
    ico_pair_name = 'ZECUSD'
    from_time_str = '2017-09-08 01:00:00'
    from_time = Time.parse(from_time_str)
    now = Time.now

    total_profit = 0.0
    total_times = 0

    while from_time < now
      previous_time = from_time - 1.hours
      to_time = from_time + 1.hours

      point_value = IcoRatio.where('pair_name = ? AND time_at > ? AND time_at < ?', ico_pair_name, previous_time, from_time).average(:ratio)
      records = IcoRatio.where('pair_name = ? AND time_at > ? AND time_at < ?', ico_pair_name, from_time, to_time)

      buy_price = 0.0
      sell_price = 0.0
      profit = 0.0
      previous_price = 0.0
      buy_ratio = 0
      buy_at = ''

      records.each do |item|
        diff = point_value - item.ratio

        if buy_price == 0.0 and previous_price > 0 and diff > 0.5 # and item.ico_price > previous_price 
          buy_price = item.ico_price
          buy_ratio = item.ratio
          buy_at = item.time_at
        end

        if buy_price > 0.0
          profit = (item.ico_price - buy_price) / buy_price * 100
          if profit > 1
            sell_price = item.ico_price
            previous_price = 0.0
            break
          else
            sell_price = item.ico_price

            # if profit < -1.5
            #   break
            # end
          end
        end

        previous_price = item.ico_price
      end

      if buy_price > 0
        puts "Buy at #{buy_price} - sell at #{sell_price} - profit #{'%.8f' % profit} - ratio #{buy_ratio} - avg_ratio #{point_value} at #{buy_at}" 
        total_profit += profit
        total_times += 1
      end

      from_time += 1.hours
    end

    puts "SUMMARY: profit #{total_profit} in #{total_times} times"
  end
end
