#  VH RUNNING
require 'bitfinex-api-rb'

namespace :ico_bot_usd_continue do
  task :start, [] => :environment do |_cmd, args|
    puts "Run rake ico_bot_usd_continue:start"
    
    threads = []
    thread_num = 1
    
    cycle_time = 20

    acc = IcoAccount.first
    if acc.site == "Bitfi"
      api_obj = Bitfi.new({
        key: acc.key,
        secret: acc.secret
      })
    end

    # Create threads
    thread_num.times do |index|
      puts "Create thread ##{index + 1}"
      thread = Thread.new{
        thread_id = index + 1

        config = {
          ico_bot: IcoBot.first,
          api_obj: api_obj,
          thread_id: thread_id
        }
        bot_obj = BotRunUsd1.new(config)
        is_first_time = true

        while true
          start_time = Time.now

          bot_obj.update_current_price()

          if is_first_time
            is_first_time = false
            next
          end

          bot_obj.save_price()
          bot_obj.find_pump()
          bot_obj.find_down() if bot_obj.price_log.analysis_pump != 1
          bot_obj.analysis()

          sleep(0.2)

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

  task :check_price, [] => :environment do |_cmd, args|
    puts "rake ico_bot_usd_continue:check_price"

    time_at = Time.now.to_i
    from = time_at - 2.hours.to_i

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
end
