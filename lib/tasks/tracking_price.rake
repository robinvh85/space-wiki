#
namespace :tracking_price do
  task :start, [] => :environment do |_cmd, args|
    puts "Run rake tracking_price:start"
    
    threads = []

    cycle_time = 60 # 2p
    thread_num = 2

    thread_num.times do |index|
      puts "Create thread #{index + 1}"
      thread = Thread.new{
        ico_list = []
        thread_id = index + 1

        while true
          start_time = Time.now
          
          # Step 1: find new ico
          puts "Thread #{thread_id}: find new trade_info at #{Time.now}"
          trade_info = BotTradeInfo.find_by("is_tracking = 0")

          if trade_info.present?
            trade_info.is_tracking = 1 # Set running
            trade_info.save!

            # Init ico
            puts "Start a new trade for #{trade_info.currency_pair_name} at #{Time.now}"
            config = {
              thread_id: thread_id,
              trade_info: trade_info,
            }  

            ico_obj = IcoTrackingPrice.new(config)
            ico_list << ico_obj
          end

          # Step 2: analysis each ico
          ico_list.each do |ico|
            ico.trade_info.reload
            if ico.trade_info.is_tracking == -1
              ico_list.delete(ico)  # Remove ico from ico_list
              next
            end

            ico.update_current_price()
            ico.analysis()
          end

          # Step3 : Sleep for next cyclce
          end_time = Time.now
          inteval = (end_time - start_time).to_i

          sleep(cycle_time - inteval) if cycle_time - inteval > 0
        end
      }

      sleep(cycle_time / thread_num)
      threads << thread
    end

    threads.each do |t|
      t.join
    end
  end
end

class IcoTrackingPrice
  attr_accessor :trade_info, :is_sold, :bot_trade_history

  def initialize(config)
    @trading_type = "BUY" # BUY or SELL
    
    @current_buy_price = 0.0
    @current_sell_price = 0.0
    @previous_buy_price = 0.0
    @previous_sell_price = 0.0
    
    @trade_info = config[:trade_info]
    @thread_id = config[:thread_id]
  end

  # Properties
  def changed_buy_percent
    if @previous_buy_price == 0
      0.0
    else
      ((@current_buy_price - @previous_buy_price) / @previous_buy_price * 100).round(2)
    end
  end

  def changed_sell_percent
    if @previous_sell_price == 0.0
      0.0
    else
      ((@current_sell_price - @previous_sell_price) / @previous_sell_price * 100).round(2)
    end
  end

  def difference_price
    if @current_buy_price == 0
      0.0
    else
      ((@current_sell_price - @current_buy_price) / @current_buy_price * 100).round(2)
    end
  end

 
  # Can create many algorithms and watching for better
  def analysis
    puts "#{@trade_info.currency_pair_name} -> Current Buy (#{'%.8f' % @current_buy_price} | #{changed_buy_percent}) - Current Sell (#{'%.8f' % @current_buy_price} | #{changed_buy_percent}) - Diff #{difference_price}"

    params = {
      currency_pair_id: @trade_info.currency_pair_id,
      currency_pair_name: @trade_info.currency_pair_name,
      current_buy_price: @current_buy_price,
      current_sell_price: @current_sell_price,
      changed_buy: changed_buy_percent,
      changed_sell: changed_sell_percent,
      difference_price: difference_price,
      previous_buy_price: @previous_buy_price,
      previous_sell_price: @previous_sell_price
    }

    Log.tracking_price(params)
  end
  
  def update_current_price
    # Backup previous price
    @previous_sell_price = @current_sell_price
    @previous_buy_price = @current_buy_price

    # Get new price
    data = Api.get_current_trading_price(@trade_info)
    @current_buy_price  = data[:buy_price]
    @current_sell_price = data[:sell_price]
  end
end
