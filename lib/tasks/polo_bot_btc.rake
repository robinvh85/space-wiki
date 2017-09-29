#  VH RUNNING
namespace :polo_bot_btc do
  task :start, [] => :environment do |_cmd, args|
    puts "Run rake polo_bot_btc:start"

    threads = []
    thread_num = 2

    cycle_time = 60

    api_obj = PoloObj.new

    polo_bot = PoloBotRun.new({
      api_obj: api_obj
    })

    # Create threads
    thread_num.times do |index|
      puts "Create thread ##{index + 1}"

      if index == 0
        thread = Thread.new{
          thread_id = index + 1

          while true
            start_time = Time.now

            order_list = PoloOrder.where("trading_type <> 'DONE'")
            order_list.each do |order|
              puts "\nStart trading for #{order.pair_name} at #{Time.now}"
              next if order.trading_type.empty?

              ico_info = IcoInfo.find_by(polo_order_id: order.id)
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
      elsif index == 1
        thread = Thread.new{
          thread_id = index + 1
          polo_obj = PoloObj.new
  
          while true
            start_time = Time.now
            puts "\n#{thread_id} run at #{Time.now}"
  
            # pair_list = CurrencyPair.where(thread_id: thread_id, is_disabled: 0)
            ico_list = IcoInfo.all
  
            ico_list.each do |ico|
              puts "#{thread_id} - #{ico.pair_name}"
              data_price = polo_obj.get_current_trading_price(ico.pair_name, 0)
              next if data_price.nil?
  
              diff_price_percent = (data_price[:sell_price] - data_price[:buy_price]) / data_price[:buy_price] * 100
              price_log = PoloPriceLog.create({
                pair_name: ico.pair_name,
                buy_price: data_price[:buy_price],
                sell_price: data_price[:sell_price],
                diff_price_percent: diff_price_percent,
                time_at: Time.now.to_i
              })
  
              # ico = IcoInfo.find_by(pair_name: pair.pair_name)
  
              # unless ico.nil?
              ico.current_price = data_price[:buy_price]
              ico.save
              # end
  
              sleep(0.1)
            end
  
            end_time = Time.now
            inteval = (end_time - start_time).to_i
  
            sleep(cycle_time - inteval) if cycle_time - inteval > 0
          end # while
        }
      end

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
    btc_price = @api_obj.get_current_trading_price('USDT_BTC', 0)
    amount_btc = @order.amount_usd / btc_price[:buy_price]
    (amount_btc / @order.buy_price).round(8)
  end

  def set_config(order, ico_info)
    @current_buy_price = 0
    @current_sell_price = 0

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

    diff_percent = (@current_buy_price - @order.buy_price) / @current_buy_price * 100
    return if diff_percent > 0.5
    return if @current_buy_price < @order.buy_price

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
      @order.is_bought = 1
      @order.trading_type = "SELLING"
      @order.save

      return if @order.level == 3

      new_buy_price = @order.buy_price - ( @order.buy_price / 100 * 1 )
      new_sell_price = @order.sell_price - ( @order.sell_price / 100 * 0.5 )

      PoloOrder.create({
        pair_name: @order.pair_name,
        ico_info_id: @order.ico_info_id,
        trading_type: 'BUYING',
        amount_usd: @order.amount_usd,
        level: @order.level + 1,
        buy_price: new_buy_price,
        sell_price: new_sell_price
      })
    end
  end

  def check_set_order_sell
    puts "##{@thread_id} - #{@order.pair_name} - check_set_order_sell() with price #{'%.8f' % @current_buy_price} at #{Time.now}"
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
      @order.is_sold = 1
      @order.trading_type = "DONE"
      @order.save

      # Reset order from ico_info
      @ico_info.polo_order_id = nil
      @ico_info.save
    end
  end

  def update_current_price
    puts "#{@order.pair_name} - update_current_price() at #{Time.now}"
    # Get new price
    data = @api_obj.get_current_trading_price(@order.pair_name, 0)

    return nil if data.nil?

    @current_buy_price = data[:buy_price]
    @current_sell_price = data[:sell_price]
  end
end
