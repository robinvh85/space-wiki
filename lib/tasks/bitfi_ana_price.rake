# 
namespace :bitfi_ana_price do
  task :start, [] => :environment do |_cmd, args|
    puts "Run rake bitfi_ana_price:start"
    pair_list = ["ETHUSD", "BCHUSD", "LTCUSD", "XRPUSD", "IOTUSD", "OMGUSD", "XMRUSD", "EOSUSD", "SANUSD", "DSHUSD", "ZECUSD", "RRTUSD", "BTCUSD", "ETCUSD"]
    #pair_list = ["BCHUSD"]

    # Analys.find_pump(pair_list)
    Analys.find_down(pair_list)
  end

  task :calc_change_buy_1m_2m, [] => :environment do |_cmd, args|
    puts "Run rake bitfi_ana_price:calc_change_buy_1m_2m"

    pair_list = ["XMRUSD"]
    Analys.change_1m_2m(pair_list)    
  end

  task :training1, [] => :environment do |_cmd, args|
    puts "Run rake bitfi_ana_price:training1"
    pair = 'XMRUSD'

    list = BitfiPriceLog.where("pair_name=? AND (
      ( analysis_pump = 1 AND change_buy_percent > 0.1 AND change_sell_percent > 0.1 ) 
      OR ( analysis_pump = -1 AND change_buy_percent < 0 )
    )", pair)

    order = {}

    list.each do |item|
      if item.analysis_pump == 1 and order['buy'].nil?
        order['buy'] = item.sell_price
        order['buy_id'] = item.id
      elsif item.analysis_pump == -1 and !order['buy'].nil?
        order['sell'] = item.buy_price
        order['sell_id'] = item.id
        
        profit = ((order['sell'] - order['buy']) / order['buy'] * 100).round(2)

        puts "ORDER profit (#{profit}%) - Buy at: ##{order['buy_id']} - #{order['buy']} => Sell at: ##{order['sell_id']} - #{order['sell']}"
        order = {}
      end
    end
  end

  task :training2, [] => :environment do |_cmd, args|
    puts "Run rake bitfi_ana_price:training2"
    pair = 'XMRUSD'

    list = BitfiPriceLog.where("pair_name=? AND (
      ( analysis_pump = 1 AND change_buy_percent > 0.1 AND change_sell_percent > 0.1 ) 
      OR ( analysis_pump = -1 AND change_buy_percent < 0 )
    )", pair)

    order = {}
    trading_type = ""

    list.each do |item|

      if trading_type == ""
        if item.analysis_pump == 1 and order['buy'].nil?
          trading_type = "BUYING"
          order['buy'] = item.sell_price
          order['buy_id'] = item.id
        end
      elsif trading_type == "BUYING"
        if item.change_buy_2m > 0
          trading_type = "BOUGHT"
        else
          order = {}
          trading_type = ""
        end
      elsif trading_type == "BOUGHT"
        if item.analysis_pump == -1 and !order['buy'].nil?
          order['sell'] = item.buy_price
          order['sell_id'] = item.id
          
          profit = ((order['sell'] - order['buy']) / order['buy'] * 100).round(2)

          puts "ORDER profit (#{profit}%) - Buy at: ##{order['buy_id']} - #{order['buy']} => Sell at: ##{order['sell_id']} - #{order['sell']}"
          order = {}
          trading_type = ""
        end
      end
    end
  end

  task :training3, [] => :environment do |_cmd, args|
    puts "Run rake bitfi_ana_price:training3"
    pair = 'XMRUSD'

    # list = BitfiPriceLog.where("pair_name=? AND (
    #   ( analysis_pump = 1 AND change_buy_percent > 0.1 AND change_sell_percent > 0.1 ) 
    #   OR ( analysis_pump = -1 AND change_buy_percent < 0 )
    # )", pair)

    list = BitfiPriceLog.where("pair_name=?", pair)

    order = {}
    trading_type = ""
    cancel_buy_count = 0

    list.each do |item|

      if trading_type == ""
        
        if order['buy'].nil? and item.analysis_pump == 1 and item.change_buy_percent > 0.1 and item.change_sell_percent > 0.1
          trading_type = "BUYING"
          cancel_buy_count = 0
          order['buy'] = item.sell_price
          order['buy_id'] = item.id
        end
      elsif trading_type == "BUYING"
        cancel_buy = false
        
        if item.change_buy_2m <= 0
          cancel_buy = true
        end

        if cancel_buy_count == 1 and (item.change_buy_percent < 0 or item.change_sell_percent < 0)
          cancel_buy = true
        elsif item.change_buy_percent <= 0 and item.change_sell_percent <= 0          
          cancel_buy_count += 1
          next
        end

        if cancel_buy
          order = {}
          trading_type = ""          
        else
          trading_type = "BOUGHT"
        end
      elsif trading_type == "BOUGHT"
        force_sell = false

        if item.analysis_pump == -1 and item.change_buy_percent < 0
          force_sell = true
        end

        if item.analysis_pump == -1 and item.change_buy_2m < 0
          force_sell = true
        end

        if force_sell
          order['sell'] = item.buy_price
          order['sell_id'] = item.id
          
          profit = ((order['sell'] - order['buy']) / order['buy'] * 100).round(2)

          puts "ORDER profit (#{profit}%) - Buy at: ##{order['buy_id']} - #{order['buy']} => Sell at: ##{order['sell_id']} - #{order['sell']}"
          order = {}
          trading_type = ""
        end
      end
    end
  end

end

class Analys
  class << self
    def find_pump(pair_list)
      
      pair_list.each do |pair|
        is_end = false

        puts "find_pump() - #{pair}"

        while true
          list = BitfiPriceLog.where("pair_name = ? AND analysis_pump IS NULL AND analysis_value > 0.02", pair).limit(500)

          break if list.length == 0

          list.each do |item|
            puts "find_pump() - #{pair} - #{item.id}"
            records = BitfiPriceLog.where("pair_name = ? AND time_at <= ?", pair, item.time_at).order(id: 'desc').limit(4)

            flag_all_active = true
            records.each do |record|
              if record.analysis_value < 0
                flag_all_active = false
                break
              end
            end

            if flag_all_active == true
              item.analysis_pump = 1
            else
              item.analysis_pump = 0
            end

            item.save
          end
        end
      end
    end

    def find_down(pair_list)

      pair_list.each do |pair|
        puts "find_down() - #{pair}"

        is_end = false

        while true
          list = BitfiPriceLog.where("pair_name = ? AND analysis_pump = 0 AND analysis_value < -0.02", pair).limit(500)

          break if list.length == 0

          list.each do |item|
            puts "find_down() - #{pair} - #{item.id}"
            records = BitfiPriceLog.where("pair_name = ? AND time_at <= ?", pair, item.time_at).order(id: 'desc').limit(4)

            flag_all_active = true
            records.each do |record|
              if record.analysis_value > 0
                flag_all_active = false
                break
              end
            end

            if flag_all_active == true
              item.analysis_pump = -1
            else
              item.analysis_pump = -2
            end

            item.save
          end
        end
      end
    end

    def change_1m_2m(pair_list)
      pair_list.each do |pair|
        while true
          list = BitfiPriceLog.where("pair_name = ? AND change_buy_1m IS NULL", pair).limit(500)
          break if list.length == 0

          list.each do |item| 
            record = BitfiPriceLog.where("pair_name = ? AND time_at >= ?", pair, item.time_at - 1.minutes.to_i).first
            
            puts "change 1m - #{pair} - #{item.id} -> #{record.id}"
            item.change_buy_1m = ((item.buy_price - record.buy_price) / record.buy_price * 100).round(2)

            record = BitfiPriceLog.where("pair_name = ? AND time_at >= ?", pair, item.time_at - 2.minutes.to_i).first
            
            puts "change 2m - #{pair} - #{item.id} -> #{record.id}"
            item.change_buy_2m = ((item.buy_price - record.buy_price) / record.buy_price * 100).round(2)

            item.save
          end
        end
      end
    end
  end
end