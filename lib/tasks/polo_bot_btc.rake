#  VH RUNNING
require 'bitfinex-api-rb'

namespace :polo_bot_btc do
  task :start, [] => :environment do |_cmd, args|
    puts "Run rake polo_bot_btc:start"
    
    threads = []
    thread_num = 1
    
    cycle_time = 60

    api_obj = PoloObj.new

    # Create threads
    thread_num.times do |index|
      puts "Create thread ##{index + 1}"
      thread = Thread.new{
        thread_id = index + 1
        bot_list = []

        while true
          start_time = Time.now

          ico_list = IcoInfo.all

          # Run bot_list
          ico_list.each do |ico|
            ico.reload

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

class PoloBotRun
  attr_accessor :ico_bot, :price_log, :previous_buy_price

  def initialize(config)
    @ico_bot = config[:ico_bot]
    @api_obj = config[:api_obj]
    @thread_id = config[:thread_id]

    @current_buy_price = 0
    @current_sell_price = 0
    @previous_buy_price = 0
    @previous_sell_price = 0

    @price_log = nil
    @top_price = 0

    @current_order = nil
    @current_order = IcoOrder.find(@ico_bot.ico_order_id) if @ico_bot.ico_order_id.present?
    @num_time_check_lose = 4 # 1m
    @is_lose = false
  end

  def buy_amount
    new_amount = (@ico_bot.amount_usd / @price_log.buy_price).round(8)
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
    elsif @ico_bot.trading_type == "SELLING"
      check_set_order_sell()
    elsif @ico_bot.trading_type == "CHECKING_ORDER_SELL"
      check_finish_order_sell()
    end
  end

  def check_set_order_for_buy
    puts "##{@thread_id} - #{@ico_bot.pair_name} - check_set_order_for_buy() with price #{'%.8f' % @current_buy_price} at #{Time.now}"

    time_before = Time.now.to_i - 1.minutes.to_i
    before_price_log = BitfiPriceLog.where("pair_name = ? AND time_at > ?", @ico_bot.pair_name, time_before).order(id: 'ASC').first

    if @current_buy_price <= before_price_log.buy_price and @current_buy_price > @ico_bot.limit_price_for_buy
      puts "##{@thread_id} - #{@ico_bot.pair_name} -> #{'%.8f' % @current_buy_price} < #{'%.8f' % before_price_log.buy_price} so return"
      return
    end

    # if @price_log.diff_price_percent <= 0.5
    #   buy_price = @price_log.buy_price
    # else
    #   return
    # end
    buy_price = @current_buy_price

    result = @api_obj.buy(@ico_bot.pair_name, buy_amount, buy_price)

    return if result.nil?

    @current_order = IcoOrder.create({
      buy_price: buy_price,
      amount_usd: @ico_bot.amount_usd,
      buy_order_id: result['order_id'],
      pair_name: @ico_bot.pair_name
    })

    @ico_bot.trading_type = "CHECKING_ORDER_BUY"
    @ico_bot.ico_order = @current_order
    @ico_bot.save
  end

  def check_finish_order_buy
    puts "##{@thread_id} - #{@ico_bot.pair_name} - check_finish_order_buy() with price #{'%.8f' % @current_buy_price} at #{Time.now}"

    status = @api_obj.check_order(@current_order.buy_order_id)

    if status == 1
      @current_order.bought_order_id = 1
      @current_order.save

      @ico_bot.trading_type = "SELLING"
      @ico_bot.save!
    end
  end

  def check_set_order_sell
    profit = 1 # 1%
    # profit = -5 if @is_lose == true

    if @is_lose
      @current_order.sell_price = @current_order.buy_price  
      @is_lose = false
    else
      @current_order.sell_price = (@current_order.buy_price + @current_order.buy_price * profit / 100.0).round(8)
    end

    @current_order.profit = profit
    amount = @api_obj.get_balances(@ico_bot.ico_name)
    @ico_bot.amount_ico = amount

    obj_sell = @api_obj.sell(@ico_bot.pair_name, @ico_bot.amount_ico, @current_order.sell_price)
    @current_order.sell_order_id = obj_sell['order_id']
    @current_order.save

    @ico_bot.trading_type = "CHECKING_ORDER_SELL"
    @ico_bot.save
  end

  def check_finish_order_sell
    current_profit = (@current_sell_price - @current_order.buy_price) / @current_order.buy_price * 100
    puts "##{@thread_id} - #{@ico_bot.pair_name} - check_finish_order_sell() with price #{'%.8f' % @current_buy_price}(#{'%.2f' % current_profit}%) - #{'%.8f' % @current_order.sell_price}(#{'%.2f' % @current_order.profit}%) at #{Time.now}"

    unless @is_lose
      current_profit = (@current_buy_price - @current_order.buy_price) / @current_order.buy_price * 100
      if current_profit < -4
        cancel_order_sell()
        return
      end
    end


    status = @api_obj.check_order(@current_order.sell_order_id)

    if status == 1
      @current_order.sold_order_id = 1
      @current_order.save
      @ico_bot.trading_type = "DONE"
      @ico_bot.save

      sleep(60 * 2)
    end
  end

  def cancel_order_sell
    puts "##{@thread_id} - #{@ico_bot.pair_name} - cancel_order_sell() with price #{'%.8f' % @current_sell_price} at #{Time.now}"

    status = @api_obj.cancel_order(@current_order.sell_order_id)

    if status == 1
      @is_lose = true
      @current_order.sell_order_id = nil
      @current_order.sell_price = nil
      @current_order.save

      @ico_bot.trading_type = "SELLING"
      @ico_bot.save
    end
  end

  def update_current_price
    # puts "update_current_price() at #{Time.now()}"
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

  def save_price
    puts "\n##{@thread_id} - #{@ico_bot.pair_name} - save_price() at #{Time.now}"
    change_buy_percent = ((@current_buy_price - @previous_buy_price) / @previous_buy_price * 100).round(2)
    change_sell_percent = ((@current_sell_price - @previous_sell_price) / @previous_sell_price * 100).round(2)
    diff_price_percent = ((@current_sell_price - @current_buy_price) / @current_buy_price * 100).round(2)

    time_at = Time.now.to_i
    records = BitfiTradeLog.where("pair_name = ? AND time_at <= ?", @ico_bot.pair_name, time_at).order(id: 'desc').limit(4)
    analysis_value = change_buy_percent
    
    records.each do |record|
      analysis_value += record.change_buy_percent
    end

    @price_log = BitfiTradeLog.new({
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
    
    @price_log.save!
  end
end
