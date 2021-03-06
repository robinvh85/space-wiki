class TempIco
  attr_accessor :trade_info, :is_sold

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
      limit_trade_percent: config[:limit_good_profit], # limit enough for sell or buy
      limit_changed_percent: config[:limit_invert_when_sell], # limit khi doi chieu de xac dinh co thuc hien buy or sell hay khong
      limit_force_sell: config[:limit_losses_profit],    # force sell when price down too high 
      interval_time: config[:interval_time],
      limit_verify_times: config[:limit_verify_times],  # Limit times for verify true value price,
      delay_time_after_sold: config[:delay_time_after_sold], # 20 seconds
      limit_pump_percent: config[:limit_pump_percent],
      delay_time_when_pump: config[:delay_time_when_pump],
      limit_force_sell_temp: config[:limit_force_sell_temp]
    }

    @limit_percent_active_bot_trade = 0.5
    @verify_times_active_bot_trade = 0
    
    @bot_trade_history = BotTempTradeHistory.create!({currency_pair_id: @trade_info.currency_pair_id, currency_pair_name: @trade_info.currency_pair_name})
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
    @vh_bought_price = ApiTemp.buy(@trade_info, @config[:buy_amount], @current_sell_price)

    TempLog.buy(@bot_trade_history, @config[:buy_amount], @vh_bought_price)

    # @vh_bought_price = @current_sell_price
    @trading_type = "SELL"
    @floor_price = 0.0
    @ceil_price = 0.0
    @verify_times = 0

    @bot_trade_history.buy_at = Time.now
    @bot_trade_history.save!
  end
  
  def sell
    # TODO: call API for buy
    ApiTemp.sell(@trade_info, @config[:buy_amount], @current_buy_price, @vh_bought_price)
    
    profit = (@current_buy_price - @vh_bought_price) / @vh_bought_price * 100
    TempLog.sell(@bot_trade_history, @config[:buy_amount], @current_buy_price, profit)

    @trading_type = "BUY"
    @floor_price = 0.0
    @ceil_price = 0.0
    @verify_times = 0
    @is_sold = true

    # sleep(@config[:delay_time_after_sold])
    @bot_trade_history.sell_at = Time.now
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
    # TODO: check khi nao gia ban va gia mua chenh lech ko qua 0.5% thi moi mua

    # do nothing when downing
    puts "#{@trade_info.currency_pair_name} ana_buy -> floor_price: #{'%.8f' % @floor_price} - previous_price: #{'%.8f' % @previous_price} - current_sell_price: #{'%.8f' % @current_sell_price} (#{current_sell_changed_with_floor_percent.round(2)}% | #{changed_sell_percent.round(2)})%"
    TempLog.analysis_buy(@trade_info, @floor_price, @previous_price, @current_sell_price, changed_sell_percent.round(2), current_sell_changed_with_floor_percent.round(2))

    if @floor_price == 0.0 || @floor_price > @previous_price  # xac dinh duoc gia tri day khi chua co gia tri day hoac khi tiep tuc giam
      @floor_price = @previous_price
    end

    if changed_sell_percent >= 0 # when price up      
      if current_sell_changed_with_floor_percent > @config[:limit_changed_percent] # buy khi gia tang lon hon nguong
        @verify_times += 1

        puts "#{@trade_info.currency_pair_name}  CALL BUY at times: #{@verify_times}"
        if @verify_times == @config[:limit_verify_times]
          buy()
        end
      end 
    end      
  end

  def analysis_for_sell
    # do nothing when upping
    # puts "ana_sell: at #{Time.now}"
    profit = (@current_buy_price - @vh_bought_price) / @vh_bought_price * 100
    puts "#{@trade_info.currency_pair_name}  ana_sell-> ceil_price: #{'%.8f' % @ceil_price} - previous_price: #{'%.8f' % @previous_price} - current_buy_price: #{'%.8f' % @current_buy_price}  (#{current_buy_changed_with_ceil_percent.round(2)}% | #{changed_buy_percent.round(2)}% => #{profit.round(2)}%)"
    TempLog.analysis_sell(@trade_info, @ceil_price, @previous_price, @current_buy_price, changed_buy_percent.round(2), current_buy_changed_with_ceil_percent.round(2), profit)

    check_active_bot_trade(profit)

    if changed_buy_percent <= 0 # when price down      
      if -current_buy_changed_with_ceil_percent > @config[:limit_changed_percent] # Co the sell khi dao chieu vuot nguong cho phep ~0.3
        if current_buy_changed_with_vh_bought_price > @config[:limit_trade_percent] # Khi dang loi ~>2%
          @verify_times += 1
          puts "#{@trade_info.currency_pair_name}  CALL SELL at times: #{@verify_times}"
          if @verify_times == @config[:limit_verify_times]
            sell()
          end
        elsif -current_buy_changed_with_ceil_percent > @config[:limit_force_sell]
          if -changed_buy_percent > @config[:limit_pump_percent] # Neu gia giam nhieu => pump
            sleep(@config[:delay_time_when_pump]) # Sleep cho qua dump
          else
            @verify_force_sell_times += 1
            puts "#{@trade_info.currency_pair_name}  CALL FORCE SELL at times: #{@verify_force_sell_times}"
            if @verify_force_sell_times == @config[:limit_verify_times]
              sell()  # Sell khi gia da giam xuong ~2% so voi gia tran
            end
          end          
        end      
      end    
    else # Khi dang tiep tuc di len      
      @verify_times = 0
      @verify_force_sell_times = 0

      if profit > @config[:limit_force_sell_temp] # Force when profit >
        puts "====> #{@trade_info.currency_pair_name}  FORCE SELL with profit #{profit.round(2)} at #{Time.now}"
        sell()
      end
    end
  end

  def check_active_bot_trade(profit)
    # Check to active realt bot trade
    return if @verify_times_active_bot_trade == -1
    
    if profit > @limit_percent_active_bot_trade
      puts "===> #{@trade_info.currency_pair_name} - Check active bot trade with profit #{profit} - verify time #{@verify_times_active_bot_trade}"
      @verify_times_active_bot_trade += 1
      if @verify_times_active_bot_trade == 2
        # TODO : set priority = 1
        puts "===> #{@trade_info.currency_pair_name} - FORCE ACTIVE"
        bot_trade_info = BotTradeInfo.find_by("priority = 0 AND id = ?", @trade_info.id)
        if bot_trade_info.present?
          bot_trade_info.priority = 1
          bot_trade_info.save!
        end

        @verify_times_active_bot_trade = -1
      end
    else
      @verify_times_active_bot_trade = 0
    end


    if @ceil_price == 0.0 || @ceil_price < @previous_price
      @ceil_price = @previous_price
    end
  end

  def update_current_price  
    # Backup previous price
    @previous_price = @current_sell_price if @trading_type == 'BUY'
    @previous_price = @current_buy_price if @trading_type == 'SELL'

    # Get new price
    data = ApiTemp.get_current_trading_price(@trade_info)
    @current_buy_price  = data[:buy_price]
    @current_sell_price = data[:sell_price]
    # puts "Get current price - Buy: #{@current_buy_price} - Sell: #{@current_sell_price} at #{Time.now}"
  end

  # def start_trading
  #   puts "start_trading: #{@trade_info.currency_pair_name} at #{Time.now}"
  #   while(true) do
  #     update_current_price()
  #     analysis()

  #     if @is_sold # If a trading cycle done
  #       return
  #     end

  #     sleep(@config[:interval_time])
  #     # flag_stop = true  # TODO : get thong tin flag stop
  #     # if flag_stop  # If stop, stop trading
  #     #   break
  #     # end
  #   end
  # end
end