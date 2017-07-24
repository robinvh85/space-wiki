# 
namespace :tracking_btc do
  task :start, [] => :environment do |_cmd, args|
    puts "Run rake tracking_btc:get_price"
    
    cycle_time = 30

    while true
      puts "Get price of BTC at #{Time.now}"
      start_time = Time.now
      result = {}
      pair_name = "USDT_BTC"
      response = PoloniexVh.order_book(pair_name)
      data = JSON.parse(response.body)

      limit_btc = 0.01
      buy_price = 0
      data['bids'].each do |bid|
        if bid[1].to_f > limit_btc
          buy_price = bid[0].to_f
          break
        end
      end

      sell_price = 0
      data['asks'].each do |ask|
        if ask[1].to_f > limit_btc
          sell_price = ask[0].to_f
          break
        end
      end

      ico_info = IcoInfo.find_by(currency_pair_name: "USDT_BTC")
      ico_info.current_buy_price = buy_price
      ico_info.current_sell_price = sell_price
      ico_info.save!

      end_time = Time.now
      inteval = (end_time - start_time).to_i

      sleep(cycle_time - inteval) if cycle_time - inteval > 0
  end
end
