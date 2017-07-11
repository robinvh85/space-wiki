namespace :ico do
  task :start_trading, [] => :environment do |_cmd, args|
    puts "Run rake ico:start_trading"
    
    currency_pair = CurrencyPair.find(60)

    config = {
      currency_pair: currency_pair,
      buy_amount: 1000
    }
    ltc = Ico.new(config)
    ltc.start_trading()
  end
end

class Ico
  def initialize(config)
    @trading_type = "BUY" # BUY or SELL
    @trading_amount = 0
    @trading_price = 0.0    
    
    @current_buy_price = 0.0
    @current_sell_price = 0.0
    @previous_price = 0.0
    @floor_price = 0.0  # when buying, value min khi doi chieu
    @ceil_price = 0.0  # when buying, value min khi doi chieu
    @vh_bought_price = 0.0

    @currency_pair = config[:currency_pair]
    @verify_times = 0

    @config = {
      buy_amount: config[:buy_amount],
      limit_trade_percent: 2, # limit enough for sell or buy
      limit_changed_percent: 0.3, # limit khi doi chieu de xac dinh co thuc hien buy or sell hay khong
      limit_force_sell: 3,    # force sell when price down too high 
      interval_time: 20,
      limit_verify_times: 2  # Limit times for verify true value price
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
    Api.buy(@currency_pair, @config[:buy_amount], @current_sell_price)
    @vh_bought_price = @current_sell_price
    @trading_type = "SELL"
    @floor_price = 0.0
    @ceil_price = 0.0
    @verify_times = 0
  end
  
  def sell
    # TODO: call API for buy
    Api.sell(@currency_pair, @config[:buy_amount], @current_buy_price, @vh_bought_price)

    @trading_type = "BUY"
    @floor_price = 0.0
    @ceil_price = 0.0
    @verify_times = 0
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
    puts "ana_buy -> floor_price: #{@floor_price} - previous_price: #{@previous_price} - current_sell_price: #{@current_sell_price} (#{current_sell_changed_with_floor_percent.round(2)}% | #{changed_sell_percent.round(2)})%"

    if @floor_price == 0.0 || @floor_price > @previous_price  # xac dinh duoc gia tri day khi chua co gia tri day hoac khi tiep tuc giam
      @floor_price = @previous_price
    end

    if changed_sell_percent >= 0 # when price up      
      if current_sell_changed_with_floor_percent > @config[:limit_changed_percent] # buy khi gia tang lon hon nguong
        @verify_times += 1

        puts "CALL BUY at times: #{@verify_times}"
        if @verify_times == @config[:limit_verify_times]
          buy()
        end
      end 
    end      
  end

  def analysis_for_sell
    # do nothing when upping
    # puts "ana_sell: at #{Time.now}"
    puts "ana_sell-> ceil_price: #{@ceil_price} - previous_price: #{@previous_price} - current_buy_price: #{@current_buy_price}  (#{current_buy_changed_with_ceil_percent.round(2)}% | #{changed_buy_percent.round(2)})%"

    if @ceil_price == 0.0 || @ceil_price < @previous_price
      @ceil_price = @previous_price 
    end

    if changed_buy_percent <= 0 # when price down      
      if -current_buy_changed_with_ceil_percent > @config[:limit_changed_percent] # Co the sell khi dao chieu vuot nguong cho phep
        if current_buy_changed_with_vh_bought_price > @config[:limit_trade_percent]
          @verify_times += 1
          puts "CALL SELL at times: #{@verify_times}"
          if @verify_times == @config[:limit_verify_times]
            sell()
          end
        elsif current_buy_changed_with_vh_bought_price < 0 # dang lo
          if -current_buy_changed_with_vh_bought_price > @config[:limit_force_sell] # neu lo qua muc cho phep thi force sell
            sell() # force sell
          end
        end
      end
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

      sleep(@config[:interval_time])
      # flag_stop = true  # TODO : get thong tin flag stop
      # if flag_stop  # If stop, stop trading
      #   break
      # end
    end
  end
end

PoloniexVh.setup do | config |
  config.key = 'VVGCGL9G-5YV2M7RC-TCTCYIFX-QBHGLPX6'
  config.secret = '0c4496e534e874a8533756ff5121f3e5be4add3c60b985157d9cf325a742c5c74fac18b1262667577c079809b084fa279110563911bcfdf75439588b858f8a59'
end

module Api
  class << self
    def get_current_trading_price(pair)
      result = {}
      response = PoloniexVh.order_book(pair.name)
      data = JSON.parse(response.body)

      {
        buy_price: data['bids'][0][0].to_f,
        sell_price: data['asks'][0][0].to_f
      }
    end

    def buy(pair, amount, price)
      puts "====> Buy #{pair.name} - Amount: #{amount} at Price: #{price} at #{Time.now}"
    end

    def sell(pair, amount, price, bought_price)
      profit = (price - bought_price) / bought_price * 100
      puts "====> Sell #{pair.name} - Amount: #{amount} with Price: #{price}(#{profit.round(2)}%) at #{Time.now}"
    end

  end
end

module Log
  class << self
  end
end