# 
require 'bitfinex-api-rb'

namespace :ico_bot do
  task :start, [] => :environment do |_cmd, args|
    puts "Run rake ico_bot:start"
    
    threads = []
    thread_num = 1
    
    bot_list = IcoBot.all

    index = 0
    bot_list.each do |bot|
      index += 1
      puts "Create thread #{index}"
      thread = Thread.new{
        thread_id = index + 1
        
        cycle_time = 15


        # Get api_obj
        ico_info = bot.ico_info

        config = nil
        if ico_info.site == "Bitfi"
          ico_account = bot.ico_account

          api_obj = Bitfi.new({
            key: ico_account.key,
            secret: ico_account.secret
          })

          config = {
            ico_bot: bot,
            api_obj: api_obj
          }
        elsif ico_info.site == "Polo"
          api_obj = PoloObj.new

          config = {
            ico_bot: bot,
            api_obj: api_obj
          }
        end
        # End Get api_obj

        bot_run = BotRunning.new(config)

        while true
          start_time = Time.now
          result = {}
          
          puts "#Thread #{thread_id} ==========>"
          bot_run.update_current_price()
          bot_run.analysis()

          end_time = Time.now
          inteval = (end_time - start_time).to_i

          sleep(cycle_time - inteval) if cycle_time - inteval > 0
        end

      }
    
      sleep(5)
      threads << thread
    end

    threads.each do |t|
      t.join
    end
  end
end

class BotRunning
  def initialize(config)
    @ico_bot = IcoBot.find(config[:bot_id])
    @api_obj = config[:api_obj]

    @current_buy_price = 0
    @current_sell_price = 0
    @previous_buy_price = 0
    @previous_sell_price = 0
    
    @limit_profit_for_buy = 1
    @limit_profit_force_buy = 0.8

    @current_order = nil
    @current_order = IcoOrder.find(@ico_bot.ico_order_id) if @ico_bot.ico_order_id.present?
  end

  def buy_amount
    new_amount = @ico_bot.amount * (@ico_bot.sell_price / @ico_bot.buy_price)
    new_amount = new_amount - new_amount * 0.0016
    new_amount
  end

  # Method

  # Can create many algorithms and watching for better
  def analysis
    puts "Analysis at #{Time.now}"
    return 0 if @previous_buy_price == 0 # next for the first time

    @ico_bot.reload

    if @ico_bot.trading_type == "SELLING"
      check_set_order_sell()
    elsif @ico_bot.trading_type == "ORDER_SELL"
      check_finish_order_sell()
    elsif @ico_bot.trading_type == "CANCEL_SELL"
      cancel_order_sell()
    elsif @ico_bot.trading_type == "BUYING"
      check_for_buy()
    elsif @ico_bot.trading_type == "ORDER_BUY"
      check_finish_order_buy()
    elsif @ico_bot.trading_type == "CANCEL_BUY"
      cancel_order_buy()
    elsif @ico_bot.trading_type == "LOSE_ORDER"
      check_finish_lose_order()
    end
  end
  
  def check_for_buy    
    current_profit = (@ico_bot.sell_price - @current_sell_price) / @current_sell_price * 100
    puts "check_for_buy() with price #{@current_sell_price} (#{'%.2f' % current_profit}%) at #{Time.now}"
    
    if @current_sell_price < @ico_bot.sell_price
      result = @api_obj.buy(@ico_bot.ico_info.name, buy_amount, @ico_bot.buy_price)

      return if result.nil?

      profit = (@ico_bot.sell_price - @ico_bot.buy_price) / @ico_bot.buy_price * 100
      @current_order.buy_order_id = result['order_id']
      @current_order.buy_price = @ico_bot.buy_price
      @current_order.profit = profit
      @current_order.save

      @ico_bot.trading_type = "ORDER_BUY"
      @ico_bot.save
    end

  end

  def check_set_order_sell
    puts "check_set_order_sell() with price #{@current_buy_price} at #{Time.now}"

    @ico_bot.reload
    if @ico_bot.status == 1
      update_balances()
      obj_sell = @api_obj.sell(@ico_bot.ico_info.name, @ico_bot.amount, @ico_bot.sell_price)
    
      return if obj_sell.nil?

      @current_order = IcoOrder.create({
        sell_price: @ico_bot.sell_price,
        amount: @ico_bot.amount,
        sell_order_id: obj_sell['order_id']
      })
    
      @ico_bot.trading_type = "ORDER_SELL"
      @ico_bot.status = 0
      @ico_bot.ico_order = @current_order
      @ico_bot.save
    end
  end

  def update_balances
    amount = @api_obj.get_balances(@ico_bot.ico_info.currency)
    @ico_bot.amount = amount
    @ico_bot.save
  end

  def check_finish_order_sell
    puts "check_finish_order_sell() with price #{@current_buy_price} at #{Time.now}"

    status = @api_obj.check_order(@current_order.sell_order_id)

    if status == 1
      @current_order.sold_order_id = 1
      @current_order.save
      @ico_bot.trading_type = "BUYING"
      @ico_bot.save
    end
  end

  def check_finish_order_buy
    puts "check_finish_order_buy() with price #{@current_sell_price} at #{Time.now}"

    lose_percent = (@current_sell_price - @ico_bot.sell_price) / @ico_bot.sell_price * 100
    if lose_percent > @ico_bot.limit_cancel_for_lose_percent
      cancel_buy_order()
      set_lose_order()

      @ico_bot.trading_type = "LOSE_ORDER"
      @ico_bot.save
    else
      status = @api_obj.check_order(@current_order.buy_order_id)

      if status == 1
        @current_order.bought_order_id = 1
        @current_order.save
        @ico_bot.trading_type = "SELLING"
        @ico_bot.save
      end
    end
  end

  def cancel_buy_order
    puts "cancel_buy_order() with price #{@current_sell_price} at #{Time.now}"

    status = @api_obj.cancel_order(@current_order.buy_order_id)

    if status == 1
      @current_order.buy_order_id = nil
      @current_order.buy_price = nil
      @current_order.profit = nil
      @current_order.save
    end
  end

  def set_lose_order
    puts "set_lose_order() with price #{@current_sell_price} at #{Time.now}"

    lose_price = @ico_bot.sell_price + (@ico_bot.sell_price * @ico_bot.force_buy_percent / 100 )
    
    new_amount = @ico_bot.amount * (@ico_bot.sell_price / lose_price)
    new_amount = new_amount - new_amount * 0.0011

    result = @api_obj.buy(@ico_bot.ico_info.name, new_amount, lose_price)

    profit = (@ico_bot.sell_price - lose_price) / lose_price * 100
    @current_order.buy_order_id = result['order_id']
    @current_order.buy_price = lose_price
    @current_order.profit = profit
    @current_order.save
  end

  def check_finish_lose_order
    puts "check_finish_lose_order() with price #{@current_sell_price} at #{Time.now}"

    if @current_sell_price < @ico_bot.sell_price
      cancel_buy_order() # Cancel lose_buy order
      @ico_bot.trading_type = "BUYING"
      @ico_bot.save
    else
      begin
        status = @api_obj.check_order(@current_order.buy_order_id)
        if status == 1
          @current_order.bought_order_id = 1
          @current_order.save
          @ico_bot.trading_type = ""
          @ico_bot.ico_order_id = nil
          @ico_bot.save
        end
      rescue Exception => e
        puts "Buy order #{@current_order.buy_order_id} is not existed!"
      end
    end
  end

  def update_current_price  
    # Backup previous price
    @previous_sell_price = @current_sell_price
    @previous_buy_price = @current_buy_price

    # Get new price
    data = @api_obj.get_current_trading_price(@ico_bot.ico_info.name, @ico_bot.limit_amount_check_price)

    return nil if data.nil?

    @ico_bot.current_buy_price = data[:buy_price]
    @ico_bot.current_sell_price = data[:sell_price]
    @ico_bot.save

    @current_buy_price  = data[:buy_price]
    @current_sell_price = data[:sell_price]
  end

  def cancel_order_sell
    puts "Cancel order sell"
    
    status = @api_obj.cancel_order(@current_order.sell_order_id)

    if status == 1
      @current_order.delete

      @ico_bot.trading_type = 'SELLING'
      @ico_bot.ico_order_id = nil
      @ico_bot.save
    end
  end

  def cancel_order_buy
    puts "Cancel order buy"
    
    status = @api_obj.cancel_order(@current_order.buy_order_id)

    if status == 1
      @current_order.buy_order_id = nil
      @current_order.buy_price = nil
      @current_order.profit = nil
      @current_order.save

      @ico_bot.trading_type = 'BUYING'
      @ico_bot.save
    end
  end

end

class Bitfi
  def initialize(config)
    Bitfinex::Client.configure do |conf|
      conf.api_key = config[:key]
      conf.secret = config[:secret]
    end

    @client = @client = Bitfinex::Client.new
  end

  def get_current_trading_price(pair_name, limit_amount)

    begin
      data = @client.orderbook(pair_name)
      
      buy_price = 0

      if data['bids'].nil?
        puts "CAN NOT GET PRICE !!!!!"
        return nil 
      end

      data['bids'].each do |bid|
        if bid["amount"].to_f > limit_amount
          buy_price = bid["price"].to_f
          break
        end
      end

      sell_price = 0
      data['asks'].each do |ask|
        if ask["amount"].to_f > limit_amount
          sell_price = ask["price"].to_f
          break
        end
      end

      {
        buy_price: buy_price,
        sell_price: sell_price
      }
    rescue Exception => e
      puts "Error #{e}"
      nil
    end
  end

  def buy(pair_name, amount, price)
    puts "====> Buy with Amount: #{amount} at Price: #{'%.8f' % price} at #{Time.now}"

    begin
      result = @client.new_order(pair_name, amount, "exchange limit", "buy", price)
    rescue Exception => e
      result = nil
    end

    puts "======> BUY FINISH at price: #{'%.8f' % price} - amount: #{amount}"
    result
  end

  def sell(pair_name, amount, price)
    puts "====> Sell Amount: #{amount} with Price: #{'%.8f' % price} at #{Time.now}"

    begin
      result = @client.new_order(pair_name, amount, "exchange limit", "sell", price)
    rescue Exception => e
      result = nil
    end

    puts "======> SELL FINISH at price: #{'%.8f' % price} - amount: #{amount}"
    result
  end

  def cancel_order(order_id)
    puts "====> Cancel order at #{Time.now}"

    status = 0
    begin
      result = @client.cancel_orders(order_id)
      status = 1
    rescue Exception => e
      puts "Error #{e}"
    end

    result
  end

  # @return status =1: sold or Bought | =0 : still alive
  def check_order(order_id)
    puts "====> Check order #{order_id} at #{Time.now}"

    begin
      result = @client.order_status(order_id)
      binding.pry
      status = 0
      if result["is_live"] == false and result["original_amount"] == result["executed_amount"]
        status = 1
      end
    rescue Exception => e
      puts "Error #{e}"
      status = -1
    end
    
    status
  end
  
  def get_balances(currency)
    puts "====> Get balances at #{Time.now}"

    begin
      result = @client.balances
      result.each do |item|
        if item["currency"] == currency
          return item["available"].to_f
        end
      end
    rescue Exception => e
      puts "Error #{e}"
    end

    nil
  end
end

module PoloObj
  class << self
    def get_current_trading_price(pair_name, limit_amount)
      result = nil

      begin
        response = PoloniexVh.order_book(pair_name)
        data = JSON.parse(response.body)
        buy_price = 0
        data['bids'].each do |bid|
          if bid[1].to_f > limit_amount
            buy_price = bid[0].to_f
            break
          end
        end

        sell_price = 0
        data['asks'].each do |ask|
          if ask[1].to_f > limit_amount
            sell_price = ask[0].to_f
            break
          end
        end

        result = {
          buy_price: buy_price,
          sell_price: sell_price
        }
      rescue Exception => e
        puts "Error #{e}"
      end

      result
    end

    def buy(pair_name, amount, price)
      puts "====> Buy with Amount: #{amount} at Price: #{'%.8f' % price} at #{Time.now}"

      begin
        result = JSON.parse(`python script/python/buy.py #{pair_name} #{'%.8f' % price} #{amount}`)
      rescue Exception => e
        puts "Error #{e}"
      end

      puts "======> BUY FINISH at price: #{'%.8f' % price} - amount: #{amount}"
      result
    end

    def sell(pair_name, amount, price)
      puts "====> Sell Amount: #{amount} with Price: #{'%.8f' % price} at #{Time.now}"
      
      begin
        result = JSON.parse(`python script/python/sell.py #{pair_name} #{'%.8f' % price} #{amount}`)
      rescue Exception => e
        puts "Error #{e}"
      end

      puts "======> SELL FINISH at price: #{'%.8f' % price} - amount: #{amount}"
      result
    end

    def cancel_order(order_id)
      puts "====> Cancel order at #{Time.now}"

      status = 0
      begin
        result = JSON.parse(`python script/python/cancel_order.py #{order_id}`)

        if result['success'] == 1
          status = 1
        end
      rescue Exception => e
        puts "Error #{e}"
      end

      status
    end

    # @return status =1: sold or Bought | =0 : still alive
    def check_order(order_id)
      puts "====> Check order #{order_id} at #{Time.now}"

      status = 0
      begin
        result = JSON.parse(`python script/python/check_trade_order.py #{order_id}`)
        if result.present?
          status = 1
        end
      rescue Exception => e
        puts "Error #{e}"
        status = -1
      end
      
      status
    end
    
    def get_balances(currency)
      puts "====> Get balances at #{Time.now}"

      begin
        result = JSON.parse(`python script/python/get_balances.py`)
        return result[currency]
      rescue Exception => e
        puts "Error #{e}"
      end

      nil
    end
  end
end


