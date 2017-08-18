# 
require 'bitfinex-api-rb'

namespace :ico_bot_usd do
  task :start, [] => :environment do |_cmd, args|
    puts "Run rake ico_bot_usd:start"
    
    threads = []
    thread_num = 2
    
    cycle_time = 20

    api_obj_hash = {}

    # Init api_obj_hash
    accounts = IcoAccount.all
    accounts.each do |acc|
      if acc.site == "Bitfi"
        api_obj = Bitfi.new({
          key: acc.key,
          secret: acc.secret
        })
        api_obj_hash[acc.site] = api_obj
      elsif acc.site == "Polo"
        api_obj = PoloObj.new
        api_obj_hash[acc.site] = api_obj
      end
    end

    running_bot_list = IcoBot.where('status <> -1').to_a

    # Create threads
    thread_num.times do |index|
      puts "Create thread ##{index + 1}"
      thread = Thread.new{
        thread_id = index + 1
        bot_list = []

        while true
          start_time = Time.now

          if running_bot_list.any?
            bot = running_bot_list.shift
          else
            bot = IcoBot.where('status = 2').first
          end

          # Find new bot
          if bot.present?
            puts "##{thread_id} init #{bot.pair_name}"
            bot.status = 0
            bot.save!

            config = {
              ico_bot: bot,
              api_obj: api_obj_hash[bot.ico_account.site],
              thread_id: thread_id
            }
            bot_obj = BotRunningUsd.new(config)
            bot_list << bot_obj
          end

          # Run bot_list
          puts "Thread ##{thread_id} run with #{bot_list.length} icos at #{Time.now}"
          bot_list.each do |bot|
            bot.ico_bot.reload

            if bot.ico_bot.status == -1
              bot_list.delete(bot)
              next
            end

            bot.update_current_price()
            bot.analysis()

            sleep(0.2)
          end

          end_time = Time.now
          inteval = (end_time - start_time).to_i

          sleep(cycle_time - inteval) if cycle_time - inteval > 0
        end # while
      }

      sleep(cycle_time / thread_num)
      threads << thread
    end

    threads.each do |t|
      t.join
    end
  end
end

class BotRunningUsd
  attr_accessor :ico_bot

  def initialize(config)
    @ico_bot = config[:ico_bot]
    @api_obj = config[:api_obj]
    @thread_id = config[:thread_id]

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
    puts "##{@thread_id} - #{@ico_bot.pair_name} - check_set_order_for_buy() with price #{'%.2f' % @current_buy_price} at #{Time.now}"
    
    return if @ico_bot.status != 1

    if @current_buy_price >= @ico_bot.buy_price
      result = @api_obj.buy(@ico_bot.pair_name, buy_amount, @ico_bot.buy_price)

      return if result.nil?

      @current_order = IcoOrder.create({
        buy_price: @ico_bot.buy_price,
        amount_usd: @ico_bot.amount_usd,
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
    puts "##{@thread_id} - #{@ico_bot.pair_name} - check_finish_order_buy() with price #{'%.8f' % @current_buy_price} at #{Time.now}"

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
    puts "##{@thread_id} - #{@ico_bot.pair_name} - Cancel order buy"
    
    status = @api_obj.cancel_order(@current_order.buy_order_id)

    if status == 1
      @current_order.delete

      @ico_bot.trading_type = 'BUYING'
      @ico_bot.ico_order_id = nil
      @ico_bot.save
    end
  end

  def check_set_order_sell
    puts "##{@thread_id} - #{@ico_bot.pair_name} - check_set_order_sell() with price #{'%.8f' % @current_buy_price} at #{Time.now}"

    if @current_sell_price > @ico_bot.buy_price
      obj_sell = @api_obj.sell(@ico_bot.pair_name, @ico_bot.amount_ico, @ico_bot.sell_price)
      return if obj_sell.nil?

      profit = (@ico_bot.sell_price - @ico_bot.buy_price) / @ico_bot.buy_price * 100
      @current_order.sell_order_id = obj_sell['order_id']
      @current_order.sell_price = @ico_bot.sell_price
      @current_order.save

      @ico_bot.trading_type = "CHECKING_ORDER_SELL"
      @ico_bot.save
    else
      @num_time_check_lose.times do |index|
        puts "##{@thread_id} - #{@ico_bot.pair_name} => Check lose time at #{index}"
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
    puts "##{@thread_id} - #{@ico_bot.pair_name} - check_finish_order_sell() with price #{'%.8f' % @current_buy_price} at #{Time.now}"

    lose_percent = (@ico_bot.buy_price - @current_buy_price) / @current_buy_price * 100
    if lose_percent > @ico_bot.limit_cancel_for_lose_percent
      @num_time_check_lose.times do |index|
        puts "##{@thread_id} - #{@ico_bot.pair_name} => Check lose time at #{index}"
        update_current_price()
        lose_percent = (@ico_bot.buy_price - @current_buy_price) / @current_buy_price * 100
        if lose_percent > @ico_bot.limit_cancel_for_lose_percent
          if index == @num_time_check_lose - 1
            cancel_order_sell()
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
        profit = (@ico_bot.sell_price - @ico_bot.buy_price) / @ico_bot.buy_price * 100

        @current_order.sold_order_id = 1
        @current_order.profit = profit
        @current_order.save
        @ico_bot.trading_type = "DONE"
        @ico_bot.save
      end
    end
  end

  def set_lose_order
    puts "##{@thread_id} - #{@ico_bot.pair_name} - set_lose_order() with price #{'%.8f' % @current_sell_price} at #{Time.now}"

    lose_price = @ico_bot.buy_price - (@ico_bot.buy_price * @ico_bot.force_sell_percent / 100 )
    
    result = @api_obj.sell(@ico_bot.pair_name, @ico_bot.amount_ico, lose_price)

    if result.present?      
      @current_order.sell_order_id = result['order_id']
      @current_order.sell_price = lose_price      
      @current_order.save

      @ico_bot.trading_type = "LOSE_ORDER"
      @ico_bot.save
    else
      puts "===> set_lose_order() ERROR"
    end
  end

  def check_finish_lose_order
    puts "##{@thread_id} - #{@ico_bot.pair_name} - check_finish_lose_order() with price #{'%.8f' % @current_sell_price} at #{Time.now}"

    if @current_sell_price > @ico_bot.sell_price
      cancel_order_sell() # Cancel lose_sell order
    else
      begin
        status = @api_obj.check_order(@current_order.buy_order_id)
        if status == 1
          profit = (@ico_bot.sell_price - @ico_bot.buy_price) / @ico_bot.buy_price * 100

          @current_order.sell_order_id = 1
          @current_order.profit = profit
          @current_order.save
          
          @ico_bot.trading_type = "DONE"
          @ico_bot.ico_order_id = nil
          @ico_bot.save
        end
      rescue Exception => e
        puts "##{@thread_id} - Buy order #{@current_order.buy_order_id} is not existed!"
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
    puts "##{@thread_id} - #{@ico_bot.pair_name} - cancel_order_sell() with price #{'%.8f' % @current_sell_price} at #{Time.now}"

    status = @api_obj.cancel_order(@current_order.sell_order_id)

    if status == 1
      @current_order.sell_order_id = nil
      @current_order.sell_price = nil
      @current_order.save

      @ico_bot.trading_type = "SELLING"
      @ico_bot.save
    end
  end

end
