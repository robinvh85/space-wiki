#### GHI CHU
# Start: 2017/07/18
# Interval long time 2p
namespace :ico_trading do
  task :start, [] => :environment do |_cmd, args|
    puts "Run rake ico_trading4:start"
    
    threads = []

    cycle_time = 120 # 2p
    thread_num = 4

    thread_num.times do |index|
      puts "Create thread #{index + 1}"
      thread = Thread.new{
        ico_list = []
        thread_id = index + 1

        while true
          start_time = Time.now
          
          # Step 1: find new ico
          puts "Thread #{thread_id}: find new trade_info at #{Time.now}"
          trade_info = BotTradeInfo.find_by("status = 0 AND run_times <> 0")

          if trade_info.present?
            # Xac dinh trade_info co chay dc hay ko
            if trade_info.run_times > 0
              trade_info.run_times -= 1
            end

            trade_info.status = 1 # Set running
            trade_info.save!

            # Init ico
            puts "Start a new trade for #{trade_info.currency_pair_name} at #{Time.now}"
            config = {
              thread_id: thread_id,
              trade_info: trade_info,
              buy_amount: trade_info.buy_amount,
              limit_invert_when_buy: trade_info.limit_invert_when_buy || 1, # VHI
              # limit_invert_when_sell: trade_info.limit_invert_when_sell || 1, # VHI
              limit_good_profit: trade_info.limit_good_profit || 2, # VHI
              limit_losses_profit: trade_info.limit_losses_profit || 2, # VHI
              # interval_time: trade_info.interval_time || 120, # 2 min
              limit_verify_times_buy: trade_info.limit_verify_times_buy || 2,  # Limit times for buy
              limit_verify_times_sell: trade_info.limit_verify_times_sell || 2,  # Limit times for sell
              limit_difference_price: trade_info.limit_difference_price || 0.6,
              limit_dump_up: trade_info.limit_dump_up || 1,
              limit_cancel_buy_percent: trade_info.limit_cancel_buy_percent || 2
            }  

            ico_obj = Ico4.new(config)
            ico_list << ico_obj
          end

          # Step 2: analysis each ico
          ico_list.each do |ico|

            # Check cancel trading
            ico.bot_trade_history.reload
            if ico.bot_trade_history.status == -1
              ico.trade_info.status = 0 # Set available for ico
              ico.trade_info.save!
              ico_list.delete(ico)  # Remove ico from ico_list
              next
            end

            ico.update_current_price()
            ico.analysis()

            if ico.is_sold # If a trading cycle done
              ico.trade_info.status = 0 # Set available for ico
              ico.trade_info.save!
              ico_list.delete(ico)  # Remove ico from ico_list
            end
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

class Ico4
  attr_accessor :trade_info, :is_sold, :bot_trade_history

  def initialize(config)
    @trading_type = "BUY" # BUY or SELL
    
    @current_buy_price = 0.0
    @current_sell_price = 0.0
    @previous_price = 0.0
    @floor_price = 0.0  # when buying, value min khi doi chieu
    @ceil_price = 0.0  # when buying, value min khi doi chieu
    @vh_bought_price = 0.0
    @vh_bought_amount = 0.0
    @is_sold = false
    
    @count_verify_force_sell = 0
    @count_verify_buy = 0
    @count_verify_sell = 0

    @trade_info = config[:trade_info]
    @thread_id = config[:thread_id]

    @config = {
      buy_amount: config[:buy_amount],
      limit_good_profit: config[:limit_good_profit], # limit enough for sell
      limit_invert_when_buy: config[:limit_invert_when_buy], # limit khi doi chieu de xac dinh co thuc hien buy or sell hay khong
      # limit_invert_when_sell: config[:limit_invert_when_sell], # limit khi doi chieu de xac dinh co thuc hien buy or sell hay khong
      limit_losses_profit: config[:limit_losses_profit],    # force sell when price down too high 
      # interval_time: config[:interval_time],
      limit_verify_times_buy: config[:limit_verify_times_buy],  # Limit times for buy
      limit_verify_times_sell: config[:limit_verify_times_sell],  # Limit times for sell
      limit_difference_price: config[:limit_difference_price],
      limit_dump_up: config[:limit_dump_up],
      limit_cancel_buy_percent: config[:limit_cancel_buy_percent]
    }

    @bot_trade_history = BotTradeHistory.create!({currency_pair_id: @trade_info.currency_pair_id, currency_pair_name: @trade_info.currency_pair_name, status: 1})
  end

  # Properties
  def changed_buy_percent
    if @previous_price == 0
      0.0
    else
      (@current_buy_price - @previous_price) / @previous_price * 100
    end
  end

  def changed_sell_percent
    if @previous_price == 0.0
      0.0
    else
      (@current_sell_price - @previous_price) / @previous_price * 100
    end
  end

  def current_sell_changed_with_floor_percent # gia muon mua mua cua VH
    if @floor_price == 0.0
      0.0
    else
      (@current_sell_price - @floor_price) / @floor_price * 100
    end
  end

  def current_buy_changed_with_ceil_percent # gia muon ban cua VH
    if @ceil_price == 0.0
      0.0
    else
      (@current_buy_price - @ceil_price) / @ceil_price * 100
    end
  end

  def current_buy_changed_with_vh_bought_price
    (@current_buy_price - @vh_bought_price) / @vh_bought_price * 100
  end

  # Method
  def buy
    @vh_bought_price = Api.buy(@trade_info, @config[:buy_amount], @current_sell_price)

    Log.buy(@bot_trade_history, @config[:buy_amount], @vh_bought_price)

    # @vh_bought_price = @current_sell_price
    @trading_type = "SELL"
    @floor_price = 0.0
    @ceil_price = @vh_bought_price

    @bot_trade_history.buy_at = Time.now
    @bot_trade_history.status = 2
    @bot_trade_history.save!
  end
  
  def sell
    Api.sell(@trade_info, @config[:buy_amount], @current_buy_price, @vh_bought_price)
    
    profit = (@current_buy_price - @vh_bought_price) / @vh_bought_price * 100
    Log.sell(@bot_trade_history, @config[:buy_amount], @current_buy_price, profit)

    @is_sold = true

    @bot_trade_history.sell_at = Time.now
    @bot_trade_history.status = 5
    @bot_trade_history.save!
  end

  # Can create many algorithms and watching for better
  def analysis
    return 0 if @previous_price == 0 # next for the first time

    if @trading_type == "BUY"
      analysis_for_buy()
    elsif @trading_type == "SELL"
      analysis_for_sell()
    end    
  end
  
  def analysis_for_buy
    puts "Thread #{@thread_id} - #{@trade_info.currency_pair_name} ana_buy -> floor: #{'%.8f' % @floor_price} - previous: #{'%.8f' % @previous_price} - current_sell: #{'%.8f' % @current_sell_price} (#{current_sell_changed_with_floor_percent.round(2)}% | #{changed_sell_percent.round(2)})%"
    Log.analysis_buy(@bot_trade_history, @floor_price, @previous_price, @current_sell_price, changed_sell_percent.round(2), current_sell_changed_with_floor_percent.round(2))

    if @floor_price == 0.0 || @floor_price > @previous_price  # xac dinh duoc gia tri day khi chua co gia tri day hoac khi tiep tuc giam
      @floor_price = @previous_price
    end

    if @bot_trade_history.status == 3 # FORCE BUY
      buy()
      return
    end

    if changed_sell_percent >= 0 # when price up

      # Check for cancel buying
      if changed_buy_percent > @config[:limit_cancel_buy_percent]
        @bot_trade_history.status = -1
        @bot_trade_history.save!
      end

      @count_verify_buy = 0 if changed_sell_percent > @config[:limit_dump_up]

      if current_sell_changed_with_floor_percent > @config[:limit_invert_when_buy] # buy khi gia tang lon hon nguong VHI
        # Kiem tra chenh lech gia
        diff_price_percent = (@current_sell_price - @current_buy_price) / @current_buy_price * 100
        if diff_price_percent > @config[:limit_difference_price]
          puts "===> #{@trade_info.currency_pair_name} - DIFFERENCE BUY AND SELL : #{'%.8f' % @current_sell_price} > #{'%.8f' % @current_buy_price} : #{diff_price_percent.round(2)}% too high"
          Log.difference_buy_sell(@bot_trade_history, @current_buy_price, @current_sell_price, diff_price_percent)
          return
        end

        # Verify time for buy
        @count_verify_buy += 1
        puts "===> #{@trade_info.currency_pair_name}  COUNT BUY #{@count_verify_buy} at #{Time.now}"
        if @count_verify_buy == @config[:limit_verify_times_buy]
          buy()
        end
      end
    else  # when price down
      @count_verify_buy = 0
    end      
  end

  def analysis_for_sell
    profit = (@current_buy_price - @vh_bought_price) / @vh_bought_price * 100
    puts "Thread #{@thread_id} - #{@trade_info.currency_pair_name}  ana_sell-> ceil: #{'%.8f' % @ceil_price} - previous: #{'%.8f' % @previous_price} - current_buy: #{'%.8f' % @current_buy_price}  (#{current_buy_changed_with_ceil_percent.round(2)}% | #{changed_buy_percent.round(2)}% => #{profit.round(2)}%)"
    Log.analysis_sell(@bot_trade_history, @ceil_price, @previous_price, @current_buy_price, changed_buy_percent.round(2), current_buy_changed_with_ceil_percent.round(2), profit)

    if @ceil_price == 0.0 || @ceil_price < @previous_price
      @ceil_price = @previous_price
    end

    if @bot_trade_history.status == 4 # FORCE SELL
      sell()
      return
    end

    if changed_buy_percent <= 0 # when price down
      if profit > @config[:limit_good_profit] # Khi dang du loi
        @count_verify_sell += 1
        puts "===> #{@trade_info.currency_pair_name} COUNT SELL #{@count_verify_sell} at #{Time.now}"

        sell() if @count_verify_sell == @config[:limit_verify_times_sell]
      elsif -current_buy_changed_with_ceil_percent > @config[:limit_losses_profit]  # Khi giam qua nhieu, toi nguong
        @count_verify_force_sell += 1
        puts "===> #{@trade_info.currency_pair_name} COUNT FORCE SELL #{@count_verify_force_sell} at #{Time.now}"
        sell() if @count_verify_force_sell == @config[:limit_verify_times_sell]
      end    
    else # Khi dang tiep tuc di len
      @count_verify_sell = 0   
      @count_verify_force_sell = 0
    end
  end

  def update_current_price
    # Backup previous price
    @previous_price = @current_sell_price if @trading_type == 'BUY'
    @previous_price = @current_buy_price if @trading_type == 'SELL'

    # Get new price
    data = Api.get_current_trading_price(@trade_info)
    @current_buy_price  = data[:buy_price]
    @current_sell_price = data[:sell_price]
  end
end
