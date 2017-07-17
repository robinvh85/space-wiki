#### GHI CHU
# Can xac dinh gia tri chan lo hop ly. Dang thu nghiem 2%

# BotTradeInfo.status: -1: disabled, 0:ready, 1: running

namespace :ico_one do
  task :start_trading, [] => :environment do |_cmd, args|
    puts "Run rake ico:start_trading"
    
    threads = []

    ico_list = ["BTC_XVC", "BTC_NOTE", "BTC_BELA", "BTC_FLO"]

    ico_list.each do |ico_name|
      puts "Create thread for #{ico_name}"
      thread = Thread.new{
        while true
          puts "Start a new trade for #{ico_name} at #{Time.now}"
          trade_info = BotTradeInfo.find_by(currency_pair_name: ico_name)

          if trade_info.present?
            config = {
              trade_info: trade_info,
              buy_amount: trade_info.buy_amount,
              limit_invert_when_buy: trade_info.limit_invert_when_sell || 0.3, # VHI
              limit_invert_when_sell: trade_info.limit_invert_when_sell || 0.3, # VHI
              limit_good_profit: trade_info.limit_good_profit || 1.5, # VHI
              limit_losses_profit: trade_info.limit_losses_profit || 1.5, # VHI
              interval_time: trade_info.interval_time || 20,
              limit_verify_times: trade_info.limit_verify_times || 2,
              delay_time_after_sold: trade_info.delay_time_after_sold || 20,
              limit_pump_percent: 2,
              delay_time_when_pump: 30
            }  

            ico_obj = IcoOne.new(config)
            ico_obj.start_trading()

            # trade_info.status = 0 # Set available for ico
            # trade_info.save!
          end

          sleep(60)
        end
      }
    end

    threads.each do |t|
      t.join
    end
  end
end