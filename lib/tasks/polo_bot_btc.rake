#  VH RUNNING
namespace :polo_bot_btc do
  task :start, [] => :environment do |_cmd, args|
    puts "Run rake polo_bot_btc:start"
    
    threads = []
    thread_num = 1
    
    cycle_time = 60

    api_obj = PoloObj.new

    polo_bot = PoloBotRun.new({
      api_obj: api_obj
    })

    # Create threads
    thread_num.times do |index|
      puts "Create thread ##{index + 1}"
      thread = Thread.new{
        thread_id = index + 1
        bot_list = []

        while true
          start_time = Time.now

          order_list = PoloOrder.all

          # Run bot_list
          order_list.each do |order|
            ico_info = IcoInfo.find(order.pair_name)
            polo_bot.set_config(order, ico_info)

            polo_bot.update_current_price()
            polo_bot.analysis()

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
  def initialize(config)
    @api_obj = config[:api_obj]
    @thread_id = 1
    @current_buy_price = 0
    @current_sell_price = 0
    # @previous_buy_price = 0
    # @previous_sell_price = 0

    @order = nil
    @ico_info = nil
  end

  def buy_amount
    (@order.amount_usd / @order.buy_price).round(8)
  end

  def set_config(order, ico_info)
    @order = order
    @ico_info = ico_info
  end

  # Method

  # Can create many algorithms and watching for better
  def analysis
    # return 0 if @previous_buy_price == 0 # next for the first time

    if @order.trading_type == "BUYING"
      check_set_order_for_buy()
    elsif @order.trading_type == "CHECKING_ORDER_BUY"
      check_finish_order_buy()
    elsif @order.trading_type == "SELLING"
      check_set_order_sell()
    elsif @order.trading_type == "CHECKING_ORDER_SELL"
      check_finish_order_sell()
    end
  end

  def check_set_order_for_buy
    puts "##{@thread_id} - #{@order.pair_name} - check_set_order_for_buy() with price #{'%.8f' % @current_buy_price} at #{Time.now}"

    diff_percent = (@current_buy_price - @order.support_price) / @order.support_price * 100
    return if diff_percent > -0.5

    result = @api_obj.buy(@order.pair_name, buy_amount, @order.buy_price)

    return if result.nil?

    @order.buy_order_id = result['order_id']
    @order.trading_type = "CHECKING_ORDER_BUY"
    @order.save
  end

  def check_finish_order_buy
    puts "##{@thread_id} - #{@order.pair_name} - check_finish_order_buy() with price #{'%.8f' % @current_buy_price} at #{Time.now}"

    status = @api_obj.check_order(@order.buy_order_id)

    if status == 1
      @order.bought_order_id = 1
      @order.trading_type = "SELLING"
      @order.save
    end
  end

  def check_set_order_sell
    ico_name = @order.pair_name.split('_')[1]
    amount = @api_obj.get_balances(ico_name)

    return if @order.sell_price < @order.buy_price

    obj_sell = @api_obj.sell(@order.pair_name, amount, @order.sell_price)
    
    @order.sell_order_id = obj_sell['order_id']
    @order.trading_type = "CHECKING_ORDER_SELL"
    @order.save
  end

  def check_finish_order_sell
    # TODO: Checking price for lose

    status = @api_obj.check_order(@order.sell_order_id)

    if status == 1
      @order.sold_order_id = 1
      @order.trading_type = "DONE"
      @order.save

      # Reset order from ico_info
      @ico_info.polo_order_id = nil
      @ico_info.save
    end
  end

  def update_current_price
    # puts "update_current_price() at #{Time.now()}"
    # Get new price
    data = @api_obj.get_current_trading_price(@order.pair_name, 0)

    return nil if data.nil?

    @current_buy_price = data[:buy_price]
    @current_sell_price = data[:sell_price]
  end
end
