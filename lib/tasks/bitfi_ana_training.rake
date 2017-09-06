# 
namespace :bitfi_ana_training do
  task :start, [] => :environment do |_cmd, args|
    puts "Run rake bitfi_ana_training:start"
    # pair_list = ["ETHUSD", "BCHUSD", "LTCUSD", "XRPUSD", "IOTUSD", "OMGUSD", "XMRUSD", "EOSUSD", "SANUSD", "DSHUSD", "ZECUSD", "RRTUSD", "BTCUSD", "ETCUSD"]
    pair_list = ["XMRUSD"]

    Analys1.find_pump(pair_list)
    Analys1.find_down(pair_list)
  end

  task :check_price, [] => :environment do |_cmd, args|
    puts "rake bitfi_ana_training:check_price"

    time_at = Time.now.to_i
    from = time_at - 30.minutes.to_i

    query = """
      SELECT *
      FROM (
        SELECT pair_name, count(analysis_pump) as analysis_pump
        FROM bitfi_price_logs
        WHERE time_at > #{from} AND time_at < #{time_at}
        AND analysis_pump = 1 AND analysis_value > 0
        GROUP BY pair_name
      ) as tb
      ORDER BY analysis_pump DESC
    """

    # records_array = ActiveRecord::Base.connection.execute(query)
    records = ActiveRecord::Base.connection.exec_query(query)

    records.each do |record|
      pair_name = record["pair_name"]

      # Get max, min price
      from = time_at - 3.hours.to_i
      query = """
        SELECT pair_name, max(buy_price) as max_price, min(buy_price) as min_price
        FROM bitfi_price_logs
        WHERE time_at > #{from} AND time_at < #{time_at}
        AND pair_name = '#{pair_name}'
      """
      data = ActiveRecord::Base.connection.exec_query(query)
      max_price = data[0]["max_price"]
      min_price = data[0]["min_price"]

      # Get current price
      query = """
        SELECT *
        FROM bitfi_price_logs
        WHERE time_at <= #{time_at} AND pair_name='#{pair_name}'
        ORDER BY id DESC
        LIMIT 1
      """
      data = ActiveRecord::Base.connection.exec_query(query)
      current_price = data[0]["sell_price"]
      percent = (current_price - min_price) / (max_price - min_price) * 100
      capa_percent = (max_price / min_price * 100 - 100)
      puts "\ncurrent: #{current_price} - min: #{min_price} - max: #{max_price}"
      puts "#{pair_name} count: #{record['analysis_pump']} - #{'%.2f' % percent}% - #{'%.2f' % capa_percent}"
    end
  end

  task :calc_change_buy_1m_2m, [] => :environment do |_cmd, args|
    puts "Run rake bitfi_ana_training:calc_change_buy_1m_2m"

    pair_list = ["XMRUSD"]
    Analys1.change_1m_2m(pair_list)   
  end

  
  task :count_up_down, [] => :environment do |_cmd, args|
    puts "Run rake bitfi_ana_training:count_up_down"

    pair_list = ["XMRUSD"]
    
    type = 'up'
    count = 0

    pair_list.each do |pair|

      while true
        list = BitfiPriceLog.where("pair_name=?", pair).order(id: 'asc')
        break if list.length == 0

        list.each do |item|
          puts "#{pair} - #{item.id}"

          if type == 'up'
            if item.change_buy_percent > 0
              count += 1
            elsif item.change_buy_percent < 0
              type = 'down'
              count = 0
            end
          elsif type == 'down'
            if item.change_buy_percent > 0
              type = 'up'
              count = 0
            elsif item.change_buy_percent < 0              
              count -= 1
            end
          end
          item.count_up_down = count
          item.save
        end
      end
    end
  end

  task :training1, [] => :environment do |_cmd, args|
    puts "Run rake bitfi_ana_training:training1"
    pair = 'XMRUSD'

    list = BitfiPriceLog.where("pair_name=? AND (
      ( analysis_pump = 1 AND change_buy_percent > 0.1 AND change_sell_percent > 0.1 ) 
      OR ( analysis_pump = -1 AND change_buy_percent < 0 )
    )", pair).order(id: 'asc')

    order = {}
    traning_id = 1
    ProfitResult.where(pair_name: pair, traning_id: traning_id).delete_all

    list.each do |item|
      if item.analysis_pump == 1 and order['buy'].nil?
        order['buy'] = item.sell_price
        order['buy_id'] = item.id
      elsif item.analysis_pump == -1 and !order['buy'].nil?
        order['sell'] = item.buy_price
        order['sell_id'] = item.id
        
        profit = ((order['sell'] - order['buy']) / order['buy'] * 100).round(2)
        order['profit'] = profit
        order['buy_at'] = item.created_at        

        puts "ORDER profit (#{profit}%) - Buy at: ##{order['buy_id']} - #{order['buy']} => Sell at: ##{order['sell_id']} - #{order['sell']}"
        Analys1.save_result(pair, order, traning_id)
        order = {}
      end
    end
  end

  task :training2, [] => :environment do |_cmd, args|
    puts "Run rake bitfi_ana_training:training2"
    pair = 'XMRUSD'

    list = BitfiPriceLog.where("pair_name=? AND (
      ( analysis_pump = 1 AND change_buy_percent > 0.1 AND change_sell_percent > 0.1 ) 
      OR ( analysis_pump = -1 AND (change_buy_percent < 0 OR change_sell_percent < 0 ) )
    )", pair).order(id: 'asc')

    order = {}
    trading_type = ""
    traning_id = 2
    ProfitResult.where(pair_name: pair, traning_id: traning_id).delete_all

    list.each do |item|
      if trading_type == ""
        if item.analysis_pump == 1 and order['buy'].nil?
          trading_type = "BUYING"          
        end
      elsif trading_type == "BUYING"
        if item.change_buy_2m > 0
          trading_type = "BOUGHT"
          order['buy'] = item.sell_price
          order['buy_id'] = item.id
        else
          order = {}
          trading_type = ""
        end
      elsif trading_type == "BOUGHT"
        if item.analysis_pump == -1

          force_sell = false

          # if item.analysis_pump == -1 and item.change_buy_percent < 0
          #   force_sell = true
          # end

          if item.change_buy_2m < 0
            force_sell = true
          end

          if force_sell
            order['sell'] = item.buy_price
            order['sell_id'] = item.id
            
            profit = ((order['sell'] - order['buy']) / order['buy'] * 100).round(2)
            order['profit'] = profit
            order['buy_at'] = item.created_at

            puts "ORDER profit (#{profit}%) - Buy at: ##{order['buy_id']} - #{order['buy']} => Sell at: ##{order['sell_id']} - #{order['sell']}"
            Analys1.save_result(pair, order, traning_id)
            order = {}
            trading_type = ""
          end
        end
      end
    end
  end

  task :training3, [] => :environment do |_cmd, args|
    puts "Run rake bitfi_ana_training:training3"
    pair = 'XMRUSD'

    list = BitfiPriceLog.where("pair_name=?", pair).order(id: 'asc')

    order = {}
    trading_type = ""
    cancel_buy_count = 0

    traning_id = 3
    ProfitResult.where(pair_name: pair, traning_id: traning_id).delete_all

    list.each do |item|

      if trading_type == ""        
        if order['buy'].nil? and item.analysis_pump == 1 and item.change_buy_percent > 0.1 and item.change_sell_percent > 0.1 and item.change_buy_2m > 1
          trading_type = "BUYING"
          cancel_buy_count = 0
          order['set_buy_id'] = item.id
        end
      elsif trading_type == "BUYING"
        cancel_buy = false
        
        if item.change_buy_2m <= 0
          cancel_buy = true
        end

        if item.change_buy_percent <= 0.1 or item.change_sell_percent <= 0.01
          cancel_buy = true
        end

        # if cancel_buy_count == 1 and (item.change_buy_percent < 0.02 or item.change_sell_percent < 0.02)
        #   cancel_buy = true
        # elsif item.change_buy_percent <= 0 and item.change_sell_percent <= 0          
        #   cancel_buy_count += 1
        #   next
        # end

        if cancel_buy_count == 0
          cancel_buy_count += 1
          next
        end

        if cancel_buy or cancel_buy_count > 2
          order = {}
          trading_type = ""          
        else
          trading_type = "BOUGHT"
          order['buy'] = item.sell_price
          order['buy_id'] = item.id
        end
      elsif trading_type == "BOUGHT"
        force_sell = false

        if item.analysis_pump == -1 and item.change_buy_percent < 0
          force_sell = true
        end

        if item.analysis_pump == -1 and item.change_buy_2m < 0
          force_sell = true
        end

        if item.analysis_pump == -2 and item.change_buy_1m < -0.2
          force_sell = true
        end

        if item.change_buy_percent < 0 and item.change_sell_percent < 0
          force_sell = true
        end

        if item.change_buy_percent < -0.4
          force_sell = true
        end

        # profit = ((item.buy_price - order['buy']) / order['buy'] * 100).round(2)
        # if profit < -1
        #   force_sell = true
        # end

        if force_sell
          order['sell'] = item.buy_price
          order['sell_id'] = item.id
          
          profit = ((order['sell'] - order['buy']) / order['buy'] * 100).round(2)
          order['profit'] = profit
          order['buy_at'] = item.created_at

          puts "ORDER profit (#{profit}%) - Buy at: ##{order['buy_id']} - #{order['buy']} => Sell at: ##{order['sell_id']} - #{order['sell']}"
          Analys1.save_result(pair, order, traning_id)
          order = {}
          trading_type = ""
        end
      end
    end
  end

  task :training4, [] => :environment do |_cmd, args|
    puts "Run rake bitfi_ana_training:training4"
    pair = 'XMRUSD'

    list = BitfiPriceLog.where("pair_name=?", pair).order(id: 'asc')

    order = {}
    trading_type = ""
    cancel_buy_count = 0

    traning_id = 4
    ProfitResult.where(pair_name: pair, traning_id: traning_id).delete_all
    list.each do |item|

      if trading_type == ""        
        if order['buy'].nil? and item.count_up_down == 10 and item.change_buy_percent > 0.05 and item.change_sell_percent > 0
          trading_type = "BUYING"
          cancel_buy_count = 0
          order['set_buy_id'] = item.id          
        end
      elsif trading_type == "BUYING"
        cancel_buy = false
        
        if item.change_buy_percent <= 0 or item.change_sell_percent <= 0
          cancel_buy = true
        end

        if cancel_buy #or cancel_buy_count > 2
          order = {}
          trading_type = ""          
        else
          trading_type = "BOUGHT"
          order['buy'] = item.sell_price
          order['buy_id'] = item.id
        end
      elsif trading_type == "BOUGHT"
        force_sell = false

        if item.count_up_down == 0
          force_sell = true
        end

        if force_sell
          order['sell'] = item.sell_price
          order['sell_id'] = item.id
          
          profit = ((order['sell'] - order['buy']) / order['buy'] * 100).round(2)
          order['profit'] = profit
          order['buy_at'] = item.created_at

          puts "ORDER profit (#{profit}%) - Buy at: ##{order['buy_id']} - #{order['buy']} => Sell at: ##{order['sell_id']} - #{order['sell']}"
          Analys1.save_result(pair, order, traning_id)
          order = {}
          trading_type = ""
        end
      end
    end
  end

  task :training5, [] => :environment do |_cmd, args|
    puts "Run rake bitfi_ana_training:training5"
    pair = 'XMRUSD'

    list = BitfiPriceLog.where("pair_name=?", pair).order(id: 'asc')

    order = {}
    trading_type = ""
    cancel_buy_count = 0

    is_sell_lose = false
    delay_count = 0
    traning_id = 5
    check_price = 0
    count_check_price = 0

    ProfitResult.where(pair_name: pair, traning_id: traning_id).delete_all
    list.each do |item|
      # if is_sell_lose and delay_count < 20
      #   delay_count += 1
      #   next
      # else
      #   is_sell_lose = false
      #   delay_count = 0
      # end

      if is_sell_lose
        if count_check_price > 50 
          if check_price > item.buy_price
            trading_type = ''
            is_sell_lose = false
          else
            count_check_price = 0
            check_price = item.buy_price
          end
        else
          count_check_price += 1
          next  
        end
      end

      if trading_type == ""        
        if order['buy'].nil? and item.analysis_pump == 1 and item.change_buy_percent > 0.01 and item.change_sell_percent > 0.01 and item.count_up_down > 0
          trading_type = "BUYING"
          cancel_buy_count = 0
          order['set_buy_id'] = item.id          

          # unless is_sell_lose
          trading_type = "BOUGHT"
          order['buy'] = item.buy_price
          order['buy_id'] = item.id
          # end
        end
      elsif trading_type == "BUYING"
        cancel_buy = false
        
        if item.change_buy_percent <= 0 or item.change_sell_percent <= 0
          cancel_buy = true
        end

        if cancel_buy #or cancel_buy_count > 2
          order = {}
          trading_type = ""          
        else
          trading_type = "BOUGHT"
          order['buy'] = item.buy_price
          order['buy_id'] = item.id
          # is_sell_lose = false
        end
      elsif trading_type == "BOUGHT"
        force_sell = false

        # if item.count_up_down == 0
        #   force_sell = true
        # end

        profit = ((item.sell_price - order['buy']) / order['buy'] * 100).round(2)
        if profit > 1 and item.change_buy_percent <= 0
          force_sell = true
        end

        if profit < -10
          force_sell = true
          is_sell_lose = true
          delay_count = 0
          count_check_price = 0
        end

        if force_sell
          order['sell'] = item.sell_price
          order['sell_id'] = item.id
          
          profit = ((order['sell'] - order['buy']) / order['buy'] * 100).round(2)
          order['profit'] = profit
          order['buy_at'] = item.created_at

          # puts "ORDER profit (#{profit}%) - Buy at: ##{order['buy_id']} - #{order['buy']} => Sell at: ##{order['sell_id']} - #{order['sell']}"
          puts "(#{profit}%)"
          Analys1.save_result(pair, order, traning_id)
          order = {}
          trading_type = ""
          check_price = item.buy_price          
        end
      end
    end
  end

  task :training6, [] => :environment do |_cmd, args|
    puts "Run rake bitfi_ana_training:training6"
    pair = 'XMRUSD'

    list = BitfiPriceLog.where("pair_name=?", pair).order(id: 'asc')

    order = {}
    trading_type = "DONE"
    cancel_buy_count = 0

    is_sell_lose = false
    delay_count = 0
    traning_id = 6
    check_price = 0
    count_check_price = 0

    ProfitResult.where(pair_name: pair, traning_id: traning_id).delete_all
    list.each do |item|
      if is_sell_lose
        if count_check_price > 30
          if check_price > item.buy_price
            trading_type = ''
            is_sell_lose = false
          else
            count_check_price = 0
            check_price = item.buy_price
          end
        else
          count_check_price += 1
          next  
        end
      elsif trading_type == 'DONE'
        if count_check_price > 10
          if check_price > item.buy_price
            trading_type = ''
          else
            count_check_price = 0
            check_price = item.buy_price
          end
        else
          count_check_price += 1
          next  
        end
      end

      if trading_type == ""        
        if order['buy'].nil? and item.analysis_pump == 1 and item.change_buy_percent > 0.01 and item.change_sell_percent > 0.01
          trading_type = "BUYING"
          cancel_buy_count = 0
          order['set_buy_id'] = item.id          

          # unless is_sell_lose
          trading_type = "BOUGHT"
          order['buy'] = item.buy_price
          order['buy_id'] = item.id
          # end
        end
      elsif trading_type == "BUYING"
        cancel_buy = false
        
        if item.change_buy_percent <= 0 or item.change_sell_percent <= 0
          cancel_buy = true
        end

        if cancel_buy #or cancel_buy_count > 2
          order = {}
          trading_type = ""          
        else
          trading_type = "BOUGHT"
          order['buy'] = item.buy_price
          order['buy_id'] = item.id
          # is_sell_lose = false
        end
      elsif trading_type == "BOUGHT"
        force_sell = false

        # if item.count_up_down == 0
        #   force_sell = true
        # end

        profit = ((item.sell_price - order['buy']) / order['buy'] * 100).round(2)
        if profit > 1 and item.change_buy_percent <= 0
          force_sell = true
        end

        if profit < -20
          force_sell = true
          is_sell_lose = true
          delay_count = 0
          count_check_price = 0
        end

        if force_sell
          order['sell'] = item.sell_price
          order['sell_id'] = item.id
          
          profit = ((order['sell'] - order['buy']) / order['buy'] * 100).round(2)
          order['profit'] = profit
          order['buy_at'] = item.created_at

          puts "(#{profit}%)"
          Analys1.save_result(pair, order, traning_id)
          order = {}
          trading_type = "DONE"
          count_check_price = 0
          check_price = item.buy_price          
        end
      end
    end
  end

  task :training7, [] => :environment do |_cmd, args|
    puts "Run rake bitfi_ana_training:training7"
    pair = 'XMRUSD'

    list = BitfiPriceLog.where("pair_name=?", pair).order(id: 'asc')

    order = {}
    trading_type = ""
    cancel_buy_count = 0

    traning_id = 7
    top_price = 0
    down_percent = 0
    is_lose = false
    count_delay = 0

    ProfitResult.where(pair_name: pair, traning_id: traning_id).delete_all
    list.each do |item|


      # Check pass lose 1
      if is_lose
        count_delay += 1
        
        if count_delay > 30
          is_lose = false
        else
          next
        end
      end

      # Check pass lose 2
      # get price before 1m
      if is_lose
        time_before = item.time_at - 1.5.minutes.to_i
        before_price_log = BitfiPriceLog.where("time_at > ?", time_before)

        if item.buy_price > before_price_log.buy_price 
          is_lose = false
        end
      end

      if trading_type == "DONE"
        if top_price < item.buy_price
          top_price = item.buy_price
        end

        down_percent = (top_price - item.buy_price) / item.buy_price * 100

        if down_percent <= 0.5
          trading_type = ''
        end

        # trading_type = ''
      end

      if trading_type == ""
        if order['buy'].nil? and item.analysis_pump == 1 and item.change_buy_percent > 0.01 and item.change_sell_percent > 0.01
          trading_type = "BUYING"
          cancel_buy_count = 0
          order['set_buy_id'] = item.id          

          trading_type = "BOUGHT"
          order['buy'] = item.buy_price
          order['buy_id'] = item.id
        end
      # elsif trading_type == "BUYING"
      #   cancel_buy = false
        
      #   if item.change_buy_percent <= 0 or item.change_sell_percent <= 0
      #     cancel_buy = true
      #   end

      #   if cancel_buy #or cancel_buy_count > 2
      #     order = {}
      #     trading_type = ""          
      #   else
      #     trading_type = "BOUGHT"
      #     order['buy'] = item.buy_price
      #     order['buy_id'] = item.id
      #   end
      elsif trading_type == "BOUGHT"
        force_sell = false

        profit = ((item.buy_price - order['buy']) / order['buy'] * 100).round(2)
        if profit > 1 and item.change_buy_percent <= 0
          force_sell = true
        end

        if item.change_buy_percent < -0.5
          force_sell = true
        end

        if profit < -1
          force_sell = true
          is_lose = true
          count_delay = 0
        end

        if force_sell

          if is_lose
            order['sell'] = item.sell_price
          else
            order['sell'] = item.sell_price
          end
          order['sell_id'] = item.id
          
          profit = ((order['sell'] - order['buy']) / order['buy'] * 100).round(2)
          order['profit'] = profit
          order['buy_at'] = item.created_at

          puts "(#{profit}%)"
          Analys1.save_result(pair, order, traning_id)
          order = {}
          trading_type = "DONE"
          max_price = item.buy_price
        end
      end
    end
  end
end

class Analys1
  class << self
    def find_pump(pair_list)
      
      pair_list.each do |pair|
        is_end = false

        puts "find_pump() - #{pair}"

        while true
          # list = BitfiPriceLog.where("pair_name = ? AND analysis_pump IS NULL AND analysis_value > 0.02", pair).limit(500)
          list = BitfiPriceLog.where("pair_name = ? AND analysis_pump IS NULL", pair).limit(500)

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

    def save_result(pair, order, traning_id)
      ProfitResult.create({
        pair_name: pair,
        buy_price: order['buy'],
        sell_price: order['sell'],
        set_buy_id: order['set_buy_id'],
        buy_id: order['buy_id'],
        sell_id: order['sell_id'],
        profit: order['profit'],
        buy_at: order['buy_at'],
        traning_id: traning_id
      })
    end
  end
end