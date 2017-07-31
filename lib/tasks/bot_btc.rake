# 
namespace :bot_btc do
  task :start, [] => :environment do |_cmd, args|
    puts "Run rake bot_btc:start"
    
    cycle_time = 15

    config = {
      bot_id: 1
    }
    bot1 = BotBtcRunning.new(config)

    while true
      start_time = Time.now
      result = {}
      
      bot1.update_current_price()
      bot1.analysis()

      end_time = Time.now
      inteval = (end_time - start_time).to_i

      sleep(cycle_time - inteval) if cycle_time - inteval > 0
    end
  end
end

class BotBtcRunning
  def initialize(config)
    @trading_type = ''
    @bot_btc = BotBtc.find(config[:bot_id])
    @current_buy_price = 0
    @current_sell_price = 0
    @previous_buy_price = 0
    @previous_sell_price = 0
    
    @limit_profit_for_buy = 1
    @limit_profit_force_buy = 0.8

    @btc_pair_id = 4
    @btc_pair_name = 'USDT_BTC'
    @current_order = nil
  end

  def buy_amount
    new_amount = @bot_btc.amount * (@bot_btc.sell_price / @bot_btc.buy_price)
    new_amount = new_amount - new_amount * 0.0016
    new_amount
  end

  # Method

  # Can create many algorithms and watching for better
  def analysis
    puts "Analysis at #{Time.now}"
    return 0 if @previous_buy_price == 0 # next for the first time

    if @trading_type == "SELLING"
      check_set_order_sell()
    elsif @trading_type == "ORDER_SELL"
      check_finish_order_sell()
    elsif @trading_type == "BUYING"
      check_for_buy()
    elsif @trading_type == "ORDER_BUY"
      check_finish_order_buy()
    elsif @trading_type == "LOSE_ORDER"
      check_finish_lose_order()
    end
  end
  
  def check_for_buy    
    puts "Tracking for buy at price #{@current_sell_price}"
    if @current_sell_price < @bot_btc.sell_price
      result = ApiBtc.buy(buy_amount, @bot_btc.buy_price)

      profit = (@bot_btc.sell_price - @bot_btc.buy_price) / @bot_btc.buy_price * 100
      @current_order.buy_order_id = result['orderNumber']
      @current_order.buy_price = @bot_btc.buy_price
      @current_order.profit = profit
      @current_order.save

      @trading_type = "ORDER_BUY"
    end

  end

  def check_set_order_sell
    puts "Tracking for sell at price #{@current_buy_price}"

    @bot_btc.reload
    if @bot_btc.status == 1
      obj_sell = ApiBtc.sell(@bot_btc.amount, @bot_btc.sell_price)
    
      @current_order = OrderBtc.create({
        sell_price: @bot_btc.sell_price,
        amount: @bot_btc.amount,
        sell_order_id: obj_sell['orderNumber']
      })
    
      @trading_type = "ORDER_SELL"
      @bot_btc.status = 0
      @bot_btc.save
    end
  end

  def check_finish_order_sell
    begin
      result = JSON.parse(`python script/python/check_trade_order.py #{@current_order.sell_order_id}`)
      if result.present?
        @current_order.sold_order_id = 1
        @current_order.save
        @trading_type = "BUYING"
      end
    rescue
      puts "Sell order #{@current_order.sell_order_id} is not existed!"
    end
  end

  def check_finish_order_buy
    lose_percent = (@current_sell_price - @bot_btc.sell_price) / @bot_btc.sell_price * 100
    if lose_percent > 0.75
      cancel_buy_order()
      set_lose_order()

      @trading_type = "LOSE_ORDER"
    else
      begin
        result = JSON.parse(`python script/python/check_trade_order.py #{@current_order.buy_order_id}`)
        if result.present?
          @current_order.bought_order_id = 1
          @current_order.save
          @trading_type = ""
        end
      rescue
        puts "Buy order #{@current_order.buy_order_id} is not existed!"
      end
    end
  end

  def cancel_buy_order
    result = JSON.parse(`python script/python/cancel_order.py #{@current_order.buy_order_id}`)

    if result['success'] == 1
      @current_order.buy_order_id = nil
      @current_order.save
    end
  end

  def set_lose_order
    lose_price = @bot_btc.sell_price + (@bot_btc.sell_price * 0.01 )
    result = ApiBtc.buy(buy_amount, lose_price)

    profit = (@bot_btc.sell_price - lose_price) / lose_price * 100
    @current_order.buy_order_id = result['orderNumber']
    @current_order.buy_price = lose_price
    @current_order.profit = profit
    @current_order.save
  end

  def check_finish_lose_order
    if @current_sell_price < @bot_btc.sell_price
      cancel_buy_order() # Cancel lose_buy order
      @trading_type = "BUYING"
    else
      begin
        result = JSON.parse(`python script/python/check_trade_order.py #{@current_order.buy_order_id}`)
        if result.present?
          @current_order.bought_order_id = 1
          @current_order.save
          @trading_type = ""
        end
      rescue
        puts "Buy order #{@current_order.buy_order_id} is not existed!"
      end
    end
  end

  def update_current_price  
    # Backup previous price
    @previous_sell_price = @current_sell_price
    @previous_buy_price = @current_buy_price

    # Get new price
    data = ApiBtc.get_current_trading_price()
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
    def get_current_trading_price()
      result = {}
      @limit_price = 0.01
      @pair_name = "USDT_BTC"
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
      @pair_name = "USDT_BTC"
      puts "====> Buy with Amount: #{amount} at Price: #{'%.8f' % price} at #{Time.now}"
      result = JSON.parse(`python script/python/buy.py #{@pair_name} #{'%.8f' % price} #{amount}`)
      
      puts "======> BUY FINISH at price: #{'%.8f' % price} - amount: #{amount}"
      result
    end

    def sell(amount, price)
      @pair_name = "USDT_BTC"
      puts "====> Sell Amount: #{amount} with Price: #{'%.8f' % price} at #{Time.now}"
      result = JSON.parse(`python script/python/sell.py #{@pair_name} #{'%.8f' % price} #{amount}`)

      puts "======> SELL FINISH at price: #{'%.8f' % price} - amount: #{amount}"
      result
    end
  end
end
