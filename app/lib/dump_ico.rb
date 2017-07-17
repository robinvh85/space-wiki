class DumpIco
  attr_accessor :trade_info, :is_sold

  def initialize(config)
    @trading_type = "down" # down mean BUY and up mean sell
    
    @current_down_price = 0.0
    @current_up_price = 0.0
    @previous_down_price = 0.0
    @previous_up_price = 0.0
    @floor_price = 0.0  # when buying, value min khi doi chieu
    @ceil_price = 0.0  # when buying, value min khi doi chieu

    @min_24h = 0
    @max_24h = 0

    @trade_info = config[:trade_info]
  end

  # Properties
  def changed_down_percent
    if @previous_down_price == 0
      0.0
    else
      (@current_down_price - @previous_down_price) / @previous_down_price * 100
    end
  end

  def changed_up_percent
    if @previous_up_price == 0.0
      0.0
    else
      (@current_up_price - @previous_up_price) / @previous_up_price * 100
    end
  end

  def current_up_changed_with_floor_percent # gia muon mua mua cua VH
    if @floor_price == 0.0
      0.0
    else
      (@current_up_price - @floor_price) / @floor_price * 100
    end
  end

  def current_down_changed_with_ceil_percent # gia muon ban cua VH
    if @ceil_price == 0.0
      0.0
    else
      (@current_down_price - @ceil_price) / @ceil_price * 100
    end
  end

    # Can create many algorithms and watching for better
  def analysis

    if @trading_type == 'up'
      if @current_up_price < @previous_up_price # Doi chieu
        @trading_type == 'down'
        @ceil_price = @current_down_price
        get_price_24h()
      end
    elsif @trading_type =='down'
      if @current_down_price > @previous_down_price # Doi chieu
        @trading_type == 'up'
        @floor_price = @current_up_price
        get_price_24h()
      end
    end

    if @trading_type == 'up' # SELL
      analysis_price_up()
    elsif @trading_type == 'down' # BUY
      analysis_price_down()
    end
  end
  
  def get_price_24h
    ico_info = IcoInfo.find_by(currency_pair_id: @trade_info.currency_pair_id)

    @min_24h = ico_info.low_24hr
    @max_24h = ico_info.high_24hr
  end

  def analysis_price_down
    puts "#{@trade_info.currency_pair_name} DOWN -> ceil_price: #{'%.8f' % @ceil_price} - previous_price: #{'%.8f' % @previous_down_price} - current_price: #{'%.8f' % @current_down_price} (#{current_down_changed_with_ceil_percent.round(2)}% | #{changed_down_percent.round(2)})%"
    if @floor_price == 0.0 || @current_down_price < @floor_price  # xac dinh duoc gia tri day khi chua co gia tri day hoac khi tiep tuc giam
      @floor_price = @current_down_price
    end
    
    @price_24h_percent = ((@current_down_price - @min_24h) - (@max_24h - @min_24h)) / (@max_24h - @min_24h) * 100

    DumpLog.analysis_down(@trade_info, @floor_price, @previous_price, @current_down_price, changed_down_percent.round(2), current_down_changed_with_ceil_percent.round(2), @price_24h_percent)
  end

  def analysis_price_up
    puts "#{@trade_info.currency_pair_name} UP -> floor_price: #{'%.8f' % @floor_price} - previous_price: #{'%.8f' % @previous_price} - current_price: #{'%.8f' % @current_up_price} (#{current_up_changed_with_floor_percent.round(2)}% | #{changed_up_percent.round(2)})%"
    if @floor_price == 0.0 || @current_up_price < @floor_price  # xac dinh duoc gia tri day khi chua co gia tri day hoac khi tiep tuc giam
      @floor_price = @current_up_price
    end
    
    @price_24h_percent = ((@current_up_price - @min_24h) - (@max_24h - @min_24h)) / (@max_24h - @min_24h) * 100

    DumpLog.analysis_up(@trade_info, @floor_price, @previous_price, @current_up_price, changed_up_percent.round(2), current_up_changed_with_floor_percent.round(2), price_24h_percent)
  end

  def update_current_price  
    # Backup previous price
    @previous_down_price = @current_down_price
    @previous_up_price = @current_up_price

    # Get new price
    data = ApiTemp.get_current_trading_price(@trade_info)
    @current_down_price  = data[:sell_price]
    @current_up_price = data[:buy_price]
  end
end