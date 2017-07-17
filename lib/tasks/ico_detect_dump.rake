#### GHI CHU
# Can xac dinh gia tri chan lo hop ly. Dang thu nghiem 2%
# BotTradeInfo.status: -1: disabled, 0:ready, 1: running
# ico_temp3:
# + Chay training toi da 15 ico
# + Chi chay training nhung ico co percentChange > 0

namespace :ico_detect_dump do
  task :start_trading, [] => :environment do |_cmd, args|
    puts "Run rake ico:start_trading temp"
    ico_list = []
    inteval = 20

    while true
      # Get 1 trade_info best and save ico to ico_list
      # ico_list max length is 15
      puts "ico_list.length is #{ico_list.length}. Check for new TradeInfo at #{Time.now}"
      if ico_list.length < 15
        trade_info = BotTradeInfo.where("temp_status = 0 AND percent_changed > -8 AND percent_changed < 10").order(percent_changed: 'DESC').first

        if trade_info.present?
          puts "Start training for #{trade_info.currency_pair_id}"

          config = {
            trade_info: trade_info,
            buy_amount: trade_info.buy_amount,
            limit_invert_when_buy: trade_info.limit_invert_when_sell || 0.3,
            limit_invert_when_sell: trade_info.limit_invert_when_sell || 0.3,
            limit_good_profit: trade_info.limit_good_profit || 2,
            limit_losses_profit: trade_info.limit_losses_profit || 2,
            interval_time: trade_info.interval_time || 20,
            limit_verify_times: trade_info.limit_verify_times || 2,
            delay_time_after_sold: trade_info.delay_time_after_sold || 20,
            limit_pump_percent: 2,
            delay_time_when_pump: 30,
            limit_force_sell_temp: trade_info.limit_force_sell_temp || 2
          }  

          ico = DumpIco.new(config)
          ico_list << ico
          trade_info.temp_status = 1
          trade_info.save!
        end
      end

      time_sleep = inteval
      time_sleep = inteval / ico_list.length if ico_list.length > 0

      # Chay training nhung ico nam trong list
      ico_list.each do |ico|
        puts "Training #{ico.trade_info.currency_pair_name}"
        ico.update_current_price()
        ico.analysis()
        
        # if ico.is_sold == true # when end of a trade cycle
        #   ico.trade_info.temp_status = 0
        #   ico.trade_info.save!
        #   ico_list.delete(ico)
        # end

        sleep(time_sleep)
      end
    end
  end
end
