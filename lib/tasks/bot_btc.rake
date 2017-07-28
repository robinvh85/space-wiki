# 
namespace :tracking_btc do
  task :start, [] => :environment do |_cmd, args|
    puts "Run rake tracking_btc:get_price"
    
    cycle_time = 15

    while true
      puts "Get price of BTC at #{Time.now}"
      start_time = Time.now
      result = {}
      
      price_obj = TrackingBtc.get_price()

      ico_info = IcoInfo.find_by(currency_pair_name: "USDT_BTC")
      ico_info.current_buy_price = price_obj[:buy_price]
      ico_info.current_sell_price = price_obj[:sell_price]
      ico_info.save!

      end_time = Time.now
      inteval = (end_time - start_time).to_i

      sleep(cycle_time - inteval) if cycle_time - inteval > 0
    end
  end

  task :check_orders, [] => :environment do |_cmd, args|
    puts "Run rake tracking_btc:check_orders"

    cycle_time = 15
    while true
      start_time = Time.now

      TrackingBtc.check_orders()

      end_time = Time.now
      inteval = (end_time - start_time).to_i

      sleep(cycle_time - inteval) if cycle_time - inteval > 0
    end
  end

  task :log_price, [] => :environment do |_cmd, args|
    puts "Run rake tracking_btc:log_price"

    cycle_time_list = [10, 20, 30, 40]
    period_type_list = ['10s', '20s', '30s', '40s']
    
    threads = []
    thread_num = 4
    thread_num.times do |index|
      puts "Create thread #{index + 1}"
      thread = Thread.new{
        thread_id = index + 1
        cycle_time = cycle_time_list[index]
        previous_price = nil
        period_type = period_type_list[index]
        while true
          puts "Thread #{thread_id} - Write log at #{Time.now}"
          start_time = Time.now

          price_obj = TrackingBtc.save_price_log(period_type, previous_price)
          previous_price = price_obj

          end_time = Time.now
          inteval = (end_time - start_time).to_i

          sleep(cycle_time - inteval) if cycle_time - inteval > 0
        end
      }
    
      sleep(2)
      threads << thread
    end

    threads.each do |t|
      t.join
    end
  end
end

class BotBtc
  attr_accessor :thread_id
  
  def initialize(config)
    @trading_type = 'SELLING'
    @amount = config[:amount] # amount of BTC use to run
    @current_buy_price = 0
    @current_sell_price = 0
    @previous_buy_price = 0
    @previous_sell_price = 0
    @sell_price_list = []
    @buy_price_list = []
    @bought_price = 0
    @limit_amount_price_list = 5
    @limit_active_sell_percent = 0.15
    @limit_active_buy_percent = 0.15

    @is_active_sell = false
    @is_active_buy = false
  end

  def change_buy_percent
    if @previous_buy_price == 0
      0.0
    else 
      ((@current_buy_price - @previous_buy_price) / @previous_buy_price * 100).round(2)).to_f
    end
  end

  def change_sell_percent
    if @previous_sell_price == 0
      0.0
    else 
      ((@current_sell_price - @previous_sell_price) / @previous_sell_price * 100).round(2)).to_f
    end
  end

  # Method
  def buy
    @bought_price = ApiBtc.buy(@amount, @current_sell_price)

    # Log.buy(@bot_trade_history, @config[:buy_amount], @vh_bought_price)

    # @vh_bought_price = @current_sell_price
    @trading_type = "SELLING"
    @floor_price = 0.0
    @ceil_price = @bought_price
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

    if @trading_type == "BUYING"
      analysis_for_buy()
    elsif @trading_type == "SELLING"
      analysis_for_sell()
    end    
  end
  
  def analysis_for_buy
    @sell_price_list << change_sell_percent
    @sell_price_list.shift if @sell_price_list.length > @limit_amount_price_list

    # TODO - check dieu kien de sell
    sell()

    # TODO - Reset nhung data can thiet khi doi trang thai tu sell sang buy
    @trading_type = "SELLING"    
  end

  def analysis_for_sell
    @sell_price_list << change_buy_percent
    @sell_price_list.shift if @sell_price_list.length > @limit_amount_price_list

    # TODO - check dieu kien de sell

    unless @is_active_sell
      if -change_buy_percent > @limit_active_sell_percent
        @is_active_sell = true
        return
      end
    end

    if @is_active_sell
      
    end

    sell()

    # TODO - Reset nhung data can thiet khi doi trang thai tu sell sang buy
    @trading_type = "BUYING"
  end

  def update_current_price  
    # Backup previous price
    @previous_sell_price = @current_sell_price
    @previous_buy_price = @current_buy_price

    # Get new price
    data = ApiBtc.get_current_trading_price(@trade_info)
    @current_buy_price  = data[:buy_price]
    @current_sell_price = data[:sell_price]
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

module ApiBtc
  class << self
    @limit_price = 0.01
    @pair_name = "USDT_BTC"

    def get_current_trading_price()
      result = {}
      
      response = PoloniexVh.order_book(@pair_name)
      data = JSON.parse(response.body)

      buy_price = 0
      data['bids'].each do |bid|
        if bid[1].to_f > @limit_price
          buy_price = bid[0].to_f
          break
        end
      end

      sell_price = 0
      data['asks'].each do |ask|
        if ask[1].to_f > @limit_price
          sell_price = ask[0].to_f
          break
        end
      end

      {
        buy_price: buy_price,
        sell_price: sell_price
      }
    end

    def buy(amount, price)
      puts "====> Buy with Amount: #{amount} at Price: #{'%.8f' % price} at #{Time.now}"
      result = JSON.parse(`python script/python/buy.py #{@pair_name} #{'%.8f' % price} #{amount}`)
      trade = result["resultingTrades"][0]
      
      puts "======> BUY FINISH at price: #{'%.8f' % price} - amount: #{amount}"
      true
    end

    def sell(amount, price)
      puts "====> Sell Amount: #{amount} with Price: #{'%.8f' % price} at #{Time.now}"
      result = JSON.parse(`python script/python/sell.py #{@pair_name} #{'%.8f' % price} #{amount}`)

      if result["resultingTrades"].length > 0
        trade = result["resultingTrades"][0]
        puts "=======> SELL FINISH with Price: #{'%.8f' % price} at #{Time.now}"
        true
      else
        false
      end
    end
  end
end
