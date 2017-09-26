# 
namespace :polo_get_price do
  task :start, [] => :environment do |_cmd, args|
    puts "Run rake polo_get_price:start"
    
    cycle_time = 60

    thread_num = 4
    threads = []

    # Create threads
    thread_num.times do |index|
      puts "Create thread ##{index + 1}"
      thread = Thread.new{
        thread_id = index + 1
        polo_obj = PoloObj.new        

        while true
          start_time = Time.now
          puts "\n#{thread_id} run at #{Time.now}"

          pair_list = CurrencyPair.where(thread_id: thread_id, is_disabled: 0)

          pair_list.each do |pair|
            puts "#{thread_id} - #{pair.name}"
            data_price = polo_obj.get_current_trading_price(pair.name)
            next if data_price.nil?

            diff_price_percent = (data_price['sell_price'] - data_price['buy_price']) / data_price['buy_price'] * 100
            price_log = PoloPriceLog.create({
              pair_name: pair.name,
              buy_price: data_price['buy_price'],
              sell_price: data_price['sell_price'],
              diff_price_percent: diff_price_percent,
              time_at: Time.now.to_i
            })
          end

          end_time = Time.now
          inteval = (end_time - start_time).to_i

          sleep(cycle_time - inteval) if cycle_time - inteval > 0
        end # while
      }

      sleep(cycle_time / thread_num)
      threads << thread
    end

    threads.each do |t|
      t.join
    end
  end
end