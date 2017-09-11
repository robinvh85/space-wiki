# 
require 'bitfinex-api-rb'

namespace :ico_bot_1 do
  task :start, [] => :environment do |_cmd, args|
    puts "Run rake ico_bot:start"
    
    threads = []
    
    ico_account_list = IcoAccount.all
    cycle_time = 30

    index = 0
    ico_account_list.each do |account|

      index += 1
      puts "Create thread #{index}"
      thread = Thread.new{
        thread_id = index
        ico_account = account
        api_obj = nil

        # Setup API
        if account.site == "Bitfi"
          api_obj = Bitfi.new({
            key: account.key,
            secret: account.secret
          })
        elsif ico_info.site == "Polo"
          api_obj = PoloObj.new
        end
        # End Get api_obj

        bot_run = BotRunning.new(config)

        while true
          start_time = Time.now
          result = {}
          
          puts "\n#Thread #{thread_id} ==========> #{bot.ico_info.name} at #{Time.now}"
          bot_run.update_current_price()
          bot_run.analysis()

          end_time = Time.now
          inteval = (end_time - start_time).to_i

          sleep(cycle_time - inteval) if cycle_time - inteval > 0
        end

      }
    
      sleep(cycle_time / bot_list.length)
      threads << thread
    end

    threads.each do |t|
      t.join
    end
  end
end
