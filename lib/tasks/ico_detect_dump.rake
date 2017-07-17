#### GHI CHU
# Can xac dinh gia tri chan lo hop ly. Dang thu nghiem 2%
# BotTradeInfo.status: -1: disabled, 0:ready, 1: running
# ico_temp3:
# + Chay training toi da 15 ico
# + Chi chay training nhung ico co percentChange > 0

namespace :ico_detect_dump do
  task :start_trading, [status_num] => :environment do |_cmd, args|
    puts "Run rake ico:start_trading temp"
    ico_list = []
    inteval = 20

    if status_num.nil
      puts "Need specify status_num ico_detect_dump:start_trading[1]"
      return
    end

    obj = BotTradeInfo.where("temp_status = ?", status_num).first
    if obj.present?
      puts "Status_num = #{status_num} has been existed. Please check it."
      return
    end

    while true
      # Get 1 trade_info best and save ico to ico_list
      # ico_list max length is 15
      puts "ico_list.length is #{ico_list.length}. Check for new TradeInfo at #{Time.now}"
      if ico_list.length < 15
        trade_info = BotTradeInfo.where("temp_status = 0").order(percent_changed: 'DESC').first

        if trade_info.present?
          puts "Start training for #{trade_info.currency_pair_id}"

          config = {
            trade_info: trade_info
          }  

          ico = DumpIco.new(config)
          ico_list << ico
          trade_info.temp_status = status_num
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
        
        sleep(time_sleep)
      end
    end
  end
end
