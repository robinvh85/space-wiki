require 'bitfinex-api-rb'

# 
namespace :bitfi_trade_amount do
  task :get_trade, [] => :environment do |_cmd, args|
    puts "Run rake bitfi_trade_amount:start"
    pair_name = "BCHUSD"

    BitfiTrade.get_trade(pair_name)
  end
end

class BitfiTrade
  class << self
    def get_trade(pair_name)
      client = Bitfinex::Client.new
      list = client.trades(pair_name, limit_trades: 50)
      
      list.each do |item|
        trade = BitfiTrade.new
        trade.tid = item['tid']
        trade.pair_name = item['pair_name']
        trade.time_at = item['timestamp']
        trade.trade_at = Time.at(item['timestamp'])
        trade.price = item['price']
        trade.amount = item['amount']
        trade.type = item['type']

        trade.save
      end
    end
  end
end