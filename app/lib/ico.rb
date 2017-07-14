class Ico
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

    @currency_pair = config[:currency_pair]

    @config = {
      buy_amount: config[:buy_amount],
      limit_trade_percent: config[:limit_good_profit], # limit enough for sell or buy
      limit_changed_percent: config[:limit_invert_when_sell], # limit khi doi chieu de xac dinh co thuc hien buy or sell hay khong
      limit_force_sell: config[:limit_losses_profit],    # force sell when price down too high 
      interval_time: config[:interval_time],
      limit_verify_times: config[:limit_verify_times],  # Limit times for verify true value price,
      delay_time_after_sold: config[:delay_time_after_sold], # 20 seconds
      limit_pump_percent: config[:limit_pump_percent],
      delay_time_when_pump: config[:delay_time_when_pump]
    }
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
    @vh_bought_price = Api.buy(@currency_pair, @config[:buy_amount], @current_sell_price)

    Log.buy(@currency_pair, @config[:buy_amount], @vh_bought_price)

    # @vh_bought_price = @current_sell_price
    @trading_type = "SELL"
    @floor_price = 0.0
    @ceil_price = 0.0
    @verify_times = 0
  end
  
  def sell
    # TODO: call API for buy
    Api.sell(@currency_pair, @config[:buy_amount], @current_buy_price, @vh_bought_price)
    
    profit = (@current_buy_price - @vh_bought_price) / @vh_bought_price * 100
    Log.sell(@currency_pair, @config[:buy_amount], @current_buy_price, profit)

    @trading_type = "BUY"
    @floor_price = 0.0
    @ceil_price = 0.0
    @verify_times = 0
    
    # sleep(@config[:delay_time_after_sold])
    @is_sold = true
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
    puts "#{@currency_pair.name} ana_buy -> floor_price: #{'%.8f' % @floor_price} - previous_price: #{'%.8f' % @previous_price} - current_sell_price: #{'%.8f' % @current_sell_price} (#{current_sell_changed_with_floor_percent.round(2)}% | #{changed_sell_percent.round(2)})%"
    Log.analysis_buy(@currency_pair, @floor_price, @previous_price, @current_sell_price, changed_sell_percent.round(2), current_sell_changed_with_floor_percent.round(2))

    if @floor_price == 0.0 || @floor_price > @previous_price  # xac dinh duoc gia tri day khi chua co gia tri day hoac khi tiep tuc giam
      @floor_price = @previous_price
    end

    if changed_sell_percent >= 0 # when price up      
      if current_sell_changed_with_floor_percent > @config[:limit_changed_percent] # buy khi gia tang lon hon nguong
        @verify_times += 1

        puts "#{@currency_pair.name}  CALL BUY at times: #{@verify_times}"
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
    puts "#{@currency_pair.name}  ana_sell-> ceil_price: #{'%.8f' % @ceil_price} - previous_price: #{'%.8f' % @previous_price} - current_buy_price: #{'%.8f' % @current_buy_price}  (#{current_buy_changed_with_ceil_percent.round(2)}% | #{changed_buy_percent.round(2)}% => #{profit.round(2)}%)"
    Log.analysis_sell(@currency_pair, @ceil_price, @previous_price, @current_buy_price, changed_buy_percent.round(2), current_buy_changed_with_ceil_percent.round(2), profit)

    if @ceil_price == 0.0 || @ceil_price < @previous_price
      @ceil_price = @previous_price
    end

    if changed_buy_percent <= 0 # when price down      
      if -current_buy_changed_with_ceil_percent > @config[:limit_changed_percent] # Co the sell khi dao chieu vuot nguong cho phep ~0.3
        if current_buy_changed_with_vh_bought_price > @config[:limit_trade_percent] # Khi dang loi ~>2%
          @verify_times += 1
          puts "#{@currency_pair.name}  CALL SELL at times: #{@verify_times}"
          if @verify_times == @config[:limit_verify_times]
            sell()
          end
        elsif -current_buy_changed_with_ceil_percent > @config[:limit_force_sell]
          if -changed_buy_percent > @config[:limit_pump_percent] # Neu gia giam nhieu => pump
            sleep(@config[:delay_time_when_pump]) # Sleep cho qua dump
          else
            @verify_force_sell_times += 1
            puts "#{@currency_pair.name}  CALL FORCE SELL at times: #{@verify_force_sell_times}"
            if @verify_force_sell_times == @config[:limit_verify_times]
              sell()  # Sell khi gia da giam xuong ~2% so voi gia tran
            end
          end          
        end      
      end    
    else # Khi dang tiep tuc di len      
      @verify_times = 0
      @verify_force_sell_times = 0
    end
  end

  def update_current_price  
    # Backup previous price
    @previous_price = @current_sell_price if @trading_type == 'BUY'
    @previous_price = @current_buy_price if @trading_type == 'SELL'

    # Get new price
    data = Api.get_current_trading_price(@currency_pair)
    @current_buy_price  = data[:buy_price]
    @current_sell_price = data[:sell_price]
    # puts "Get current price - Buy: #{@current_buy_price} - Sell: #{@current_sell_price} at #{Time.now}"
  end

  def start_trading
    puts "start_trading: #{@currency_pair.name} at #{Time.now}"
    while(true) do
      update_current_price()
      analysis()

      if @is_sold # If a trading cycle done
        return
      end

      sleep(@config[:interval_time])
      # flag_stop = true  # TODO : get thong tin flag stop
      # if flag_stop  # If stop, stop trading
      #   break
      # end
    end
  end
end