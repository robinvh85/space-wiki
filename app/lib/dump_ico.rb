class DumpIco
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

    # Can create many algorithms and watching for better
  def analysis
    analysis_price()
  end
  
  def analysis_price
    # TODO: check khi nao gia ban va gia mua chenh lech ko qua 0.5% thi moi mua

    # do nothing when downing
    puts "#{@trade_info.currency_pair_name} ana_buy -> floor_price: #{'%.8f' % @floor_price} - previous_price: #{'%.8f' % @previous_price} - current_sell_price: #{'%.8f' % @current_sell_price} (#{current_sell_changed_with_floor_percent.round(2)}% | #{changed_sell_percent.round(2)})%"
    if @floor_price == 0.0 || @current_sell_price < @floor_price  # xac dinh duoc gia tri day khi chua co gia tri day hoac khi tiep tuc giam
      @floor_price = @current_sell_price
    end
    
    DumpLog.analysis_buy(@trade_info, @floor_price, @previous_price, @current_sell_price, changed_sell_percent.round(2), current_sell_changed_with_floor_percent.round(2))
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
end