#### GHI CHU
# Interval long time 2p

# BotTradeInfo.status: -1: disabled, 0:ready, 1: running

namespace :ico_main_one3 do
  task :start_trading, [] => :environment do |_cmd, args|
    puts "Run rake ico_main_one3:start_trading"
    
    threads = []

    ico_list = ["BTC_VIA", "BTC_FCT", "BTC_NXT", "BTC_DCR"]

    ico_list.each do |ico_name|
      puts "Create thread for #{ico_name}"
      thread = Thread.new{
        while true
          puts "Start a new trade for #{ico_name} at #{Time.now}"
          trade_info = BotTradeInfo.find_by("currency_pair_name = ? AND status = 0", ico_name)
          trade_info.status = 1 # Set running
          trade_info.save!

          if trade_info.present?
            config = {
              trade_info: trade_info,
              buy_amount: trade_info.buy_amount,
              limit_invert_when_buy: trade_info.limit_invert_when_buy || 1, # VHI
              limit_invert_when_sell: trade_info.limit_invert_when_sell || 1, # VHI
              limit_good_profit: trade_info.limit_good_profit || 2, # VHI
              limit_losses_profit: trade_info.limit_losses_profit || 2, # VHI
              interval_time: trade_info.interval_time || 120, # 2 min
              limit_verify_times: trade_info.limit_verify_times || 2,
              delay_time_after_sold: trade_info.delay_time_after_sold || 20,
              limit_pump_percent: 2,
              delay_time_when_pump: 30
            }  

            ico_obj = IcoOne3.new(config)
            ico_obj.start_trading()

            trade_info.status = 0 # Set available for ico
            trade_info.save!
          end

          sleep(30)
        end
      }

      sleep(15)
      threads << thread
    end

    threads.each do |t|
      t.join
    end
  end
end

class IcoOne3
  def initialize(config)
    @trading_type = "BUY" # BUY or SELL
    
    @current_buy_price = 0.0
    @current_sell_price = 0.0
    @previous_price = 0.0
    @floor_price = 0.0  # when buying, value min khi doi chieu
    @ceil_price = 0.0  # when buying, value min khi doi chieu
    @vh_bought_price = 0.0
    @vh_bought_amount = 0.0
    @verify_times = 0
    @verify_force_sell_times = 0
    @is_sold = false

    @trade_info = config[:trade_info]

    @config = {
      buy_amount: config[:buy_amount],
      limit_good_profit: config[:limit_good_profit], # limit enough for sell or buy
      limit_invert_when_buy: config[:limit_invert_when_buy], # limit khi doi chieu de xac dinh co thuc hien buy or sell hay khong
      limit_invert_when_sell: config[:limit_invert_when_sell], # limit khi doi chieu de xac dinh co thuc hien buy or sell hay khong
      limit_losses_profit: config[:limit_losses_profit],    # force sell when price down too high 
      interval_time: config[:interval_time],
      limit_verify_times: config[:limit_verify_times],  # Limit times for verify true value price,
      delay_time_after_sold: config[:delay_time_after_sold], # 20 seconds
      limit_pump_percent: config[:limit_pump_percent],
      delay_time_when_pump: config[:delay_time_when_pump]
    }

    @limit_odd_price_percent = 0.6
    @bot_trade_history = BotTradeHistory.create!({currency_pair_id: @trade_info.currency_pair_id, currency_pair_name: @trade_info.currency_pair_name})

    @count_profit_force_sell = 0
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
    # TODO: call API for sell
    @vh_bought_price = Api.buy(@trade_info, @config[:buy_amount], @current_sell_price)

    Log.buy(@bot_trade_history, @config[:buy_amount], @vh_bought_price)

    # @vh_bought_price = @current_sell_price
    @trading_type = "SELL"
    @floor_price = 0.0
    @ceil_price = @vh_bought_price
    @verify_times = 0

    @bot_trade_history.buy_at = Time.now
    @bot_trade_history.save!
  end
  
  def sell
    # TODO: call API for buy
    Api.sell(@trade_info, @config[:buy_amount], @current_buy_price, @vh_bought_price)
    
    profit = (@current_buy_price - @vh_bought_price) / @vh_bought_price * 100
    Log.sell(@bot_trade_history, @config[:buy_amount], @current_buy_price, profit)

    @trading_type = "BUY"
    @floor_price = 0.0
    @ceil_price = 0.0
    @verify_times = 0
    @count_profit_force_sell = 0
    
    # sleep(@config[:delay_time_after_sold])
    @is_sold = true

    @bot_trade_history.sell_at = Time.now
    @bot_trade_history.save!

    # @trade_info.priority = 0  # Reset priority to active
    # @trade_info.save!
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
    # do nothing when downing
    puts "#{@trade_info.currency_pair_name} ana_buy -> floor_price: #{'%.8f' % @floor_price} - previous_price: #{'%.8f' % @previous_price} - current_sell_price: #{'%.8f' % @current_sell_price} (#{current_sell_changed_with_floor_percent.round(2)}% | #{changed_sell_percent.round(2)})%"
    Log.analysis_buy(@trade_info, @floor_price, @previous_price, @current_sell_price, changed_sell_percent.round(2), current_sell_changed_with_floor_percent.round(2))

    if @floor_price == 0.0 || @floor_price > @previous_price  # xac dinh duoc gia tri day khi chua co gia tri day hoac khi tiep tuc giam
      @floor_price = @previous_price
    end

    # ico_info = IcoInfo.find_by(currency_pair_id: @trade_info.currency_pair_id)
    # if ico_info.present?
    #   max_change = ico_info.high_24hr - ico_info.low_24hr
    #   current_percent = (@current_sell_price - ico_info.low_24hr) / (ico_info.high_24hr - ico_info.low_24hr) * 100

    #   if current_percent > 90
    #     puts "===> #{@trade_info.currency_pair_name} price to high #{current_percent.round(2)}% in 24h => NOT BUY"
    #     return
    #   end
    # end

    if changed_sell_percent >= 0 # when price up     
      if current_sell_changed_with_floor_percent > @config[:limit_invert_when_buy] # buy khi gia tang lon hon nguong VHI
        # Kiem tra chenh lech gia
        odd_price_percent = (@current_sell_price - @current_buy_price) / @current_buy_price * 100
        if odd_price_percent > @limit_odd_price_percent
          puts "===> #{@trade_info.currency_pair_name} - DIFFERENCE BUY AND SELL : #{'%.8f' % @current_sell_price} > #{'%.8f' % @current_buy_price} : #{odd_price_percent.round(2)}% too high"
          Log.difference_buy_sell(@trade_info, @current_buy_price, @current_sell_price, odd_price_percent)
          return
        end

        5.times do |index|
          puts "===> #{@trade_info.currency_pair_name}  COUNT BUY #{index + 1} at #{Time.now}"
          if index > 0
            update_current_price()
            
            if @current_sell_price >= @previous_price && (index + 1) == @config[:limit_verify_times]
              buy()
              break
            end
          end

          if (index + 1) == @config[:limit_verify_times] # End loop
            break
          end

          sleep(30)
        end
      end 
    end      
  end

  def analysis_for_sell
    # do nothing when upping
    # puts "ana_sell: at #{Time.now}"
    profit = (@current_buy_price - @vh_bought_price) / @vh_bought_price * 100
    puts "#{@trade_info.currency_pair_name}  ana_sell-> ceil_price: #{'%.8f' % @ceil_price} - previous_price: #{'%.8f' % @previous_price} - current_buy_price: #{'%.8f' % @current_buy_price}  (#{current_buy_changed_with_ceil_percent.round(2)}% | #{changed_buy_percent.round(2)}% => #{profit.round(2)}%)"
    Log.analysis_sell(@trade_info, @ceil_price, @previous_price, @current_buy_price, changed_buy_percent.round(2), current_buy_changed_with_ceil_percent.round(2), profit)

    if @ceil_price == 0.0 || @ceil_price < @previous_price
      @ceil_price = @previous_price
    end

    if changed_buy_percent <= 0 # when price down
      # Profit for sell: chot loi
      if profit > @config[:limit_good_profit]
        5.times do |index|
          puts "===> #{@trade_info.currency_pair_name} COUNT FORCE SELL #{index + 1} at #{Time.now} "
          if index > 0
            update_current_price()
            
            if @current_buy_price <= @previous_price && (index + 1) == @config[:limit_verify_times]
              sell()
              break
            end
          end

          if (index + 1) == @config[:limit_verify_times] # End loop
            break
          end

          sleep(30)
        end
      elsif -current_buy_changed_with_ceil_percent > @config[:limit_losses_profit]  # VHI
        5.times do |index|
          puts "===> #{@trade_info.currency_pair_name} COUNT FORCE SELL #{index + 1} at #{Time.now} "
          if index > 0
            update_current_price()
            
            if -current_buy_changed_with_ceil_percent > @config[:limit_losses_profit]
              sell()  # Sell khi gia da giam xuong ~2% so voi gia tran
              break
            end
          end

          if (index + 1) == @config[:limit_verify_times] # End loop
            break
          end

          sleep(30)
        end      
      end    
    else # Khi dang tiep tuc di len      
      @verify_times = 0
      @verify_force_sell_times = 0
      @count_profit_force_sell = 0
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
    # puts "Get current price - Buy: #{@current_buy_price} - Sell: #{@current_sell_price} at #{Time.now}"
  end

  def start_trading
    puts "start_trading: #{@trade_info.currency_pair_name} at #{Time.now}"
    while(true) do
      start_time = Time.now

      update_current_price()
      analysis()

      end_time = Time.now
      inteval = (end_time - start_time).to_i

      sleep(@config[:interval_time] - inteval) if @config[:interval_time] - inteval > 0

      if @is_sold # If a trading cycle done
        return
      end      
    end
  end
end