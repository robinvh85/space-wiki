# 
namespace :bitfi_ana_price do
  task :start, [] => :environment do |_cmd, args|
    puts "Run rake bitfi_ana_price:start"
    pair_list = ["ETHUSD", "BCHUSD", "LTCUSD", "XRPUSD", "IOTUSD", "OMGUSD", "XMRUSD", "EOSUSD", "SANUSD", "DSHUSD", "ZECUSD", "RRTUSD", "BTCUSD", "ETCUSD"]
    #pair_list = ["BCHUSD"]

    # Analys.find_pump(pair_list)
    Analys.find_down(pair_list)
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
  end
end