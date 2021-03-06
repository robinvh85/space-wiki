# 
require 'bitfinex-api-rb'

namespace :ico_bot_pump do
  task :start, [] => :environment do |_cmd, args|
    puts "Run rake ico_bot_pump:start"
    
    cycle_time = 20

    acc = IcoAccount.find_by(site: 'Bitfi')
    api_obj = Bitfi.new({
      key: acc.key,
      secret: acc.secret
    })

    running_bot_list = IcoBot.where(trading_type: 'DONE_ORDER').to_a

    bot_list = []
    
    running_bot_list.each do |bot|
      if bot.present?
        config = {
          ico_bot: bot,
          api_obj: api_obj
        }

        bot_obj = BotPump.new(config)
        bot_list << bot_obj
      end
    end

    while true
      start_time = Time.now

      # Run bot_list
      bot_list.each do |bot|
        bot.ico_bot.reload

        bot.update_current_price()
        bot.check_pump()
        bot.analysis()

        sleep(0.2)
      end

      end_time = Time.now
      inteval = (end_time - start_time).to_i

      sleep(cycle_time - inteval) if cycle_time - inteval > 0
    end
  end
end

class BotPump
  attr_accessor :ico_bot

  def initialize(config)
    @ico_bot = config[:ico_bot]
    @api_obj = config[:api_obj]
    @thread_id = 1

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
  def check_pump
    # Check for buy

    if @ico_bot.trading_type == "DONE_ORDER"
      puts "##{@thread_id} - #{@ico_bot.pair_name} - checkpump() DONE_ORDER with price #{@current_buy_price} at #{Time.now}"
      price_logs = BitfiPriceLog.where(pair_name: @ico_bot.pair_name).order(id: 'desc').limit(2)

      if price_logs[0].analysis_pump == 1 and price_logs[0].analysis_value > 0.5 and price_logs[0].change_buy_percent > 0.3 and price_logs[0].change_sell_percent > 0.3
        @ico_bot.trading_type = "FORCE_BUY"
      else
        return
      end
      
      if price_logs[1].analysis_pump == 1 and price_logs[1].analysis_value > 0.5 and price_logs[1].change_buy_percent > 0.3 and price_logs[1].change_sell_percent > 0.3
        @ico_bot.trading_type = "FORCE_BUY"
      else
        @ico_bot.trading_type = ""
      end
    elsif @ico_bot.trading_type == "BOUGHT"
      puts "##{@thread_id} - #{@ico_bot.pair_name} - checkpump() BOUGHT with price #{@current_buy_price} at #{Time.now}"
      price_log = BitfiPriceLog.where(pair_name: @ico_bot.pair_name).last
      if price_log.analysis_pump == -1
        @ico_bot.trading_type = "FORCE_SELL"
      end
    end

    @ico_bot.save
  end

  # Can create many algorithms and watching for better
  def analysis
    return 0 if @previous_buy_price == 0 # next for the first time

    @ico_bot.reload

    if @ico_bot.trading_type == "FORCE_BUY"
      check_set_force_order_for_buy()
    elsif @ico_bot.trading_type == "CHECKING_ORDER_BUY"
      check_finish_order_buy()
    elsif @ico_bot.trading_type == "FORCE_SELL"
      check_set_force_sell()
    elsif @ico_bot.trading_type == "CHECKING_ORDER_SELL"
      check_finish_order_sell()
    # elsif @ico_bot.trading_type == "LOSE_ORDER"
    #   check_finish_lose_order()
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

  def check_set_force_order_for_buy    
    puts "##{@thread_id} - #{@ico_bot.pair_name} - check_set_force_order_for_buy() with price #{'%.2f' % @current_buy_price} at #{Time.now}"
    
    result = @api_obj.buy(@ico_bot.pair_name, buy_amount, @current_sell_price)

    return if result.nil?

    buy_price = @ico_bot.buy_price
    buy_price = @current_sell_price if @current_sell_price < @ico_bot.buy_price

    @current_order = IcoOrder.create({
      buy_price: buy_price,
      amount_usd: @ico_bot.amount_usd,
      buy_order_id: result['order_id'],
      pair_name: @ico_bot.pair_name
    })

    @ico_bot.buy_price = buy_price
    @ico_bot.trading_type = "CHECKING_ORDER_BUY"
    @ico_bot.status = 0
    @ico_bot.ico_order = @current_order
    @ico_bot.save
  end

  def check_set_force_sell
    puts "##{@thread_id} - #{@ico_bot.pair_name} - check_set_force_sell() with buy price #{'%.2f' % @current_buy_price} at #{Time.now}"
    
    @ico_bot.sell_price = @current_buy_price
    obj_sell = @api_obj.sell(@ico_bot.pair_name, @ico_bot.amount_ico, @ico_bot.sell_price)
    return if obj_sell.nil?

    profit = (@ico_bot.sell_price - @ico_bot.buy_price) / @ico_bot.buy_price * 100
    @current_order.sell_order_id = obj_sell['order_id']
    @current_order.sell_price = @ico_bot.sell_price
    @current_order.save

    @ico_bot.trading_type = "CHECKING_ORDER_SELL"
    @ico_bot.save
  end

  def check_finish_order_buy
    puts "##{@thread_id} - #{@ico_bot.pair_name} - check_finish_order_buy() with price #{'%.8f' % @current_buy_price} at #{Time.now}"

    status = @api_obj.check_order(@current_order.buy_order_id)

    if status == 1
      @current_order.bought_order_id = 1
      @current_order.save

      amount = @api_obj.get_balances(@ico_bot.ico_name)
      @ico_bot.amount_ico = amount
      # @ico_bot.trading_type = "SELLING"
      @ico_bot.trading_type = "BOUGHT"
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

    # lose_percent = (@ico_bot.buy_price - @current_buy_price) / @current_buy_price * 100
    # if lose_percent > @ico_bot.limit_cancel_for_lose_percent
    #   @num_time_check_lose.times do |index|
    #     puts "##{@thread_id} - #{@ico_bot.pair_name} => Check lose time at #{index}"
    #     update_current_price()
    #     lose_percent = (@ico_bot.buy_price - @current_buy_price) / @current_buy_price * 100
    #     if lose_percent > @ico_bot.limit_cancel_for_lose_percent
    #       if index == @num_time_check_lose - 1
    #         cancel_order_sell()
    #         set_lose_order()
    #       end

    #       sleep(20)
    #     else
    #       return
    #     end
    #   end
    # else
    status = @api_obj.check_order(@current_order.sell_order_id)

    if status == 1
      profit = (@current_order.sell_price - @current_order.buy_price) / @current_order.buy_price * 100

      @current_order.sold_order_id = 1
      @current_order.profit = profit
      @current_order.save
      @ico_bot.trading_type = "DONE_ORDER"
      @ico_bot.limit_price_for_buy = @current_order.sell_price
      @ico_bot.save
      # end
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
          profit = (@current_order.sell_price - @current_order.buy_price) / @current_order.buy_price * 100

          @current_order.sold_order_id = 1
          @current_order.profit = profit
          @current_order.save
          
          @ico_bot.trading_type = "DONE_ORDER"
          @ico_bot.limit_price_for_buy = @current_order.sell_price
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

  def save_current_price
    return if @previous_buy_price == 0

    puts "##{@thread_id} - #{@ico_bot.pair_name} - save_current_price() at #{Time.now}"
    change_buy_percent = ((@current_buy_price - @previous_buy_price) / @previous_buy_price * 100).round(2)
    change_sell_percent = ((@current_sell_price - @previous_sell_price) / @previous_sell_price * 100).round(2)
    diff_price_percent = ((@current_sell_price - @current_buy_price) / @current_buy_price * 100).round(2)

    time_at = Time.now.to_i
    records = IcoPriceLog.where("pair_name = ? AND time_at <= ?", @ico_bot.pair_name, time_at).order(id: 'desc').limit(4)
    analysis_value = change_buy_percent
    
    records.each do |record|
      analysis_value += record.change_buy_percent
    end

    IcoPriceLog.create({
      pair_name: @ico_bot.pair_name,
      buy_price: @current_buy_price,
      sell_price: @current_sell_price,
      change_buy_percent: change_buy_percent,
      change_sell_percent: change_sell_percent,
      diff_price_percent: diff_price_percent,
      period_type: '20s',
      analysis_value: analysis_value,
      time_at: time_at
    })
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
