require 'bitfinex-api-rb'

# 
namespace :bitfi_trade_amount do
  task :get_trade, [] => :environment do |_cmd, args|
    puts "Run rake bitfi_trade_amount:get_trade"
    pair_name = "BCHUSD"

    BitfiTradeAmount.get_trade(pair_name)
  end
end

class BitfiTradeAmount
  class << self
    def get_trade(pair_name)
      client = Bitfinex::Client.new
      list = client.trades(pair_name, limit_trades: 200)

      list.each do |item|
        next if item['amount'].to_i < 10
        BitfiTrade.where(tid: item['tid']).first_or_create do |trade|
          trade.tid = item['tid']
          trade.pair_name = pair_name
          trade.time_at = item['timestamp']
          trade.trade_at = Time.at(item['timestamp'])
          trade.price = item['price']
          trade.amount = item['amount']
          trade.trade_type = item['type']
        end
      end
    end
  end
end