# 
require 'bitfinex-api-rb'

namespace :ico_bot_usd do
  task :start, [] => :environment do |_cmd, args|
    puts "Run rake ico_bot_usd:start"
    
    threads = []
    thread_num = 1
    
    bot_list = IcoBot.where('status <> -1')
    cycle_time = 20

    index = 0
    bot_list.each do |bot|
      index += 1
      puts "Create thread #{index}"
      thread = Thread.new{
        thread_id = index

        # Get api_obj
        config = nil
        ico_account = bot.ico_account
        if ico_account.site == "Bitfi"
          api_obj = Bitfi.new({
            key: ico_account.key,
            secret: ico_account.secret
          })

          config = {
            ico_bot: bot,
            api_obj: api_obj
          }
        elsif ico_account.site == "Polo"
          api_obj = PoloObj.new

          config = {
            ico_bot: bot,
            api_obj: api_obj
          }
        end
        # End Get api_obj

        bot_run = BotRunningUsd.new(config)

        while true
          start_time = Time.now
          result = {}
          
          puts "\n#Thread #{thread_id} ==========> #{bot.pair_name} at #{Time.now}"
          bot_run.update_current_price()
          bot_run.analysis()

          end_time = Time.now
          inteval = (end_time - start_time).to_i

          sleep(cycle_time - inteval) if cycle_time - inteval > 0
        end

      }
    
      sleep(cycle_time / bot_list.length)
      threads << thread
    end

    threads.each do |t|
      t.join
    end
  end
end

class BotRunningUsd
  def initialize(config)
    @ico_bot = config[:ico_bot]
    @api_obj = config[:api_obj]

    @current_buy_price = 0
    @current_sell_price = 0
    @previous_buy_price = 0
    @previous_sell_price = 0
    
    @current_order = nil
    @current_order = IcoOrder.find(@ico_bot.ico_order_id) if @ico_bot.ico_order_id.present?
    @num_time_check_lose = 4 # 1m
  end

  def buy_amount
    new_amount = (@ico_bot.amount_usd / @ico_bot.buy_price).round(8)
    new_amount
  end

  # Method

  # Can create many algorithms and watching for better
  def analysis
    return 0 if @previous_buy_price == 0 # next for the first time

    @ico_bot.reload

    if @ico_bot.trading_type == "BUYING"
      check_set_order_for_buy()
    elsif @ico_bot.trading_type == "CHECKING_ORDER_BUY"
      check_finish_order_buy()
    elsif @ico_bot.trading_type == "CANCEL_BUY"
      cancel_order_buy()
    elsif @ico_bot.trading_type == "SELLING"
      check_set_order_sell()
    elsif @ico_bot.trading_type == "CHECKING_ORDER_SELL"
      check_finish_order_sell()
    elsif @ico_bot.trading_type == "CANCEL_SELL"
      cancel_order_sell()
    elsif @ico_bot.trading_type == "LOSE_ORDER"
      check_finish_lose_order()
    end
  end
  
  def check_set_order_for_buy    
    puts "#{@ico_bot.pair_name} - check_set_order_for_buy() with price #{'%.2f' % @current_buy_price} at #{Time.now}"
    
    return if @ico_bot.status != 1

    if @current_buy_price > @ico_bot.buy_price
      result = @api_obj.buy(@ico_bot.pair_name, buy_amount, @ico_bot.buy_price)

      return if result.nil?

      @current_order = IcoOrder.create({
        buy_price: @ico_bot.buy_price,
        amount: @ico_bot.amount,
        buy_order_id: result['order_id'],
        pair_name: @ico_bot.pair_name
      })

      @ico_bot.trading_type = "CHECKING_ORDER_BUY"
      @ico_bot.status = 0
      @ico_bot.ico_order = @current_order
      @ico_bot.save
    end
  end

   def check_finish_order_buy
    puts "#{@ico_bot.pair_name} - check_finish_order_buy() with price #{'%.8f' % @current_buy_price} at #{Time.now}"

    status = @api_obj.check_order(@current_order.buy_order_id)

    if status == 1
      @current_order.bought_order_id = 1
      @current_order.save

      amount = @api_obj.get_balances(@ico_bot.ico_name)
      @ico_bot.amount_ico = amount
      @ico_bot.trading_type = "SELLING"
      @ico_bot.save
    end
  end

  def cancel_order_buy
    puts "#{@ico_bot.pair_name} - Cancel order buy"
    
    status = @api_obj.cancel_order(@current_order.buy_order_id)

    if status == 1
      @current_order.delete

      @ico_bot.trading_type = 'BUYING'
      @ico_bot.ico_order_id = nil
      @ico_bot.save
    end
  end

  def check_set_order_sell
    puts "#{@ico_bot.pair_name} - check_set_order_sell() with price #{'%.8f' % @current_buy_price} at #{Time.now}"

    if @current_sell_price > @ico_bot.buy_price
      obj_sell = @api_obj.sell(@ico_bot.pair_name, @ico_bot.amount, @ico_bot.sell_price)
      return if obj_sell.nil?

      profit = (@ico_bot.sell_price - @ico_bot.buy_price) / @ico_bot.buy_price * 100
      @current_order.sell_order_id = obj_sell['order_id']
      @current_order.sell_price = @ico_bot.sell_price
      @current_order.profit = profit
      @current_order.save

      @ico_bot.trading_type = "CHECKING_ORDER_SELL"
      @ico_bot.save
    else
      @num_time_check_lose.times do |index|
        puts "#{@ico_bot.pair_name} => Check lose time at #{index}"
        update_current_price()
        lose_percent = (@ico_bot.buy_price - @current_buy_price) / @current_buy_price * 100
        if lose_percent > @ico_bot.limit_cancel_for_lose_percent
          if index == @num_time_check_lose - 1
            set_lose_order()            
          end

          sleep(20)
        else
          return
        end
      end
    end
  end

  def check_finish_order_sell
    puts "#{@ico_bot.pair_name} - check_finish_order_sell() with price #{'%.8f' % @current_buy_price} at #{Time.now}"

    lose_percent = (@ico_bot.buy_price - @current_buy_price) / @current_buy_price * 100
    if lose_percent > @ico_bot.limit_cancel_for_lose_percent
      @num_time_check_lose.times do |index|
        puts "#{@ico_bot.ico_info.name} => Check lose time at #{index}"
        update_current_price()
        lose_percent = (@ico_bot.buy_price - @current_buy_price) / @current_buy_price * 100
        if lose_percent > @ico_bot.limit_cancel_for_lose_percent
          if index == @num_time_check_lose - 1
            cancel_sell_order()
            set_lose_order()
          end

          sleep(20)
        else
          return
        end
      end
    else
      status = @api_obj.check_order(@current_order.sell_order_id)

      if status == 1
        @current_order.sold_order_id = 1
        @current_order.save
        @ico_bot.trading_type = "DONE"
        @ico_bot.save
      end
    end
  end

  def cancel_sell_order
    puts "#{@ico_bot.ico_info.name} - cancel_sell_order() with price #{'%.8f' % @current_sell_price} at #{Time.now}"

    status = @api_obj.cancel_order(@current_order.sell_order_id)

    if status == 1
      @current_order.sell_order_id = nil
      @current_order.sell_price = nil
      @current_order.profit = nil
      @current_order.save

      @ico_bot.trading_type = "SELLING"
      @ico_bot.save
    end
  end

  def set_lose_order
    puts "#{@ico_bot.pair_name} - set_lose_order() with price #{'%.8f' % @current_sell_price} at #{Time.now}"

    lose_price = @ico_bot.buy_price - (@ico_bot.buy_price * @ico_bot.force_sell_percent / 100 )
    
    result = @api_obj.sell(@ico_bot.pair_name, @ico_bot.amount, lose_price)

    if result.present?
      profit = (lose_price - @ico_bot.buy_price) / @ico_bot.buy_price * 100
      @current_order.sell_order_id = result['order_id']
      @current_order.sell_price = lose_price
      @current_order.profit = profit
      @current_order.save

      @ico_bot.trading_type = "LOSE_ORDER"
      @ico_bot.save
    else
      puts "===> set_lose_order() ERROR"
    end
  end

  def check_finish_lose_order
    puts "#{@ico_bot.pair_name} - check_finish_lose_order() with price #{'%.8f' % @current_sell_price} at #{Time.now}"

    if @current_sell_price > @ico_bot.sell_price
      cancel_sell_order() # Cancel lose_sell order
    else
      begin
        status = @api_obj.check_order(@current_order.buy_order_id)
        if status == 1
          @current_order.bought_order_id = 1
          @current_order.save
          @ico_bot.trading_type = "DONE"
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
    data = @api_obj.get_current_trading_price(@ico_bot.pair_name, @ico_bot.limit_amount_check_price)

    return nil if data.nil?

    @ico_bot.current_buy_price = data[:buy_price]
    @ico_bot.current_sell_price = data[:sell_price]
    @ico_bot.save

    @current_buy_price  = data[:buy_price]
    @current_sell_price = data[:sell_price]
  end

  def cancel_order_sell
    puts "#{@ico_bot.pair_name} - Cancel order sell"
    
    status = @api_obj.cancel_order(@current_order.sell_order_id)

    if status == 1      
      @ico_bot.trading_type = 'SELLING'
      @ico_bot.ico_order_id = nil
      @ico_bot.save
    end
  end

end
