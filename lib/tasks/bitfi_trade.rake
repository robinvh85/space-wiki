require 'bitfinex-api-rb'

namespace :bitfi_trade do
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
end
