# 
namespace :ico_check_price do
  task :start, [] => :environment do |_cmd, args|
    puts "Run rake ico_check_price:start"
    
    cycle_time = 20

    thread_num = 2
    api_obj_hash = {}
    threads = []

    # Init api_obj_hash
    accounts = IcoAccount.all
    accounts.each do |acc|
      if acc.site == "Bitfi"
        api_obj = Bitfi.new({
          key: acc.key,
          secret: acc.secret
        })
        api_obj_hash[acc.site] = api_obj
      elsif acc.site == "Polo"
        api_obj = PoloObj.new
        api_obj_hash[acc.site] = api_obj
      end
    end

    running_bot_list = IcoBot.where('status <> -1').to_a

    # Create threads
    thread_num.times do |index|
      puts "Create thread ##{index + 1}"
      thread = Thread.new{
        thread_id = index + 1
        bot_list = []

        while true
          start_time = Time.now

          if running_bot_list.any?
            bot = running_bot_list.shift
          else
            bot = IcoBot.where('status = 2').first
          end

          # Find new bot
          if bot.present?
            puts "##{thread_id} init #{bot.pair_name}"
            config = {
              ico_bot: bot,
              api_obj: api_obj_hash[bot.ico_account.site],
              thread_id: thread_id
            }
            bot_obj = BotRunningUsd.new(config)
            bot_list << bot_obj
          end

          # Run bot_list
          puts "Thread ##{thread_id} run with #{bot_list.length} icos at #{Time.now}"
          bot_list.each do |bot|
            bot.ico_bot.reload

            if bot.ico_bot.status == -1
              bot_list.delete(bot)
              next
            end

            bot.update_current_price()
            bot.save_current_price()

            sleep(0.2)
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
