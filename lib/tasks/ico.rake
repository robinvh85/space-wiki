namespace :ico do
  task :start_trading, [] => :environment do |_cmd, args|
    puts "Run rake ico:start_trading"
    
  end
end

class Ico
  def initialize()
    @status = ""  # UP or DOWN
    @trading_type = "BUY" # BUY or SELL
    @trading_amount = 0
    @trading_price = 0.0    
    
    @current_buy_price = 0.0
    @current_sell_price = 0.0
    @previous_price = 0.0
    @floor_price = 0.0  # when buying, value min khi doi chieu
    @ceil_price = 0.0  # when buying, value min khi doi chieu


    @currency_pair = ""

    @config = {
      buy_amount: 1000
      limit_trade_percent: 2 # limit enough for sell or buy
      limit_changed_percent: 0.1 # limit khi doi chieu
      limit_force_sell: 3    # force sell when price down too high 
    }
  end

  # Properties
  def changed_buy_percent
    (@current_buy_price - @previous_price) / @previous_price * 100
  end

  def changed_sell_percent
    (@current_sell_price - @previous_price) / @previous_price * 100
  end

  def changed_buy_with_floor_percent
    (@current_buy_price - @floor_price) / @floor_price * 100
  end

  def changed_sell_with_ceil_percent
    (@current_buy_price - @ceil_price) / @ceil_price * 100
  end

  # Method
  def buy
    # TODO: call API for sell
    @trading_type = "SELL"
    @floor_price = 0.0
  end
  
  def sell
    # TODO: call API for buy
    @trading_type = "BUY"
    @ceil_price = 0.0
  end

  # Can create many algorithms and watching for better
  def analysis
    return 0 if @previous_price == 0 # next for the first time

    if @trading_type == "BUY"
      if changed_sell_percent > 0 # Khi doi chieu
        @floor_price = @previous_price if @floor_price == 0.0  # xac dinh duoc gia tri day khi chua co gia tri day
        buy() if changed_sell_with_floor_percent > @config.limit_changed_percent # Up
      end      
    elsif @trading_type == "SELL"
      if changed_buy_percent < 0 
        @ceil_price = @previous_price if @ceil_price == 0.0
        sell() if -changed_buy_with_ceil_percent > @config.limit_trade_percent # Down
      end
    end    
  end
  
  def update_current_price  
    # Backup previous price
    @previous_price = @current_sell_price if @trading_type == 'BUY'
    @previous_price = @current_buy_price if @trading_type == 'SELL'

    # Get new price
    @current_buy_price  = _get_new_buy_price_api()
    @current_sell_price = _get_new_sell_price_api()
  end

  def start_trading
    while(true) do            
      update_current_price()
      analysis()

      sleep(15)
      flag_stop = true  # TODO : get thong tin flag stop
      if flag_stop  # If stop, stop trading
        break
      end
    end
  end
end
