class BotRunUsd4
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

    if @ico_bot.trading_type == "DONE"
      pair_name = specify_better_ico(Time.now.to_i)

      return if pair_name.nil?

      @ico_bot.pair_name = pair_name
      @ico_bot.ico_name = pair_name[0..2].downcase
      @ico_bot.trading_type = "BUYING"
      @ico_bot.save!
      return
    end

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

  def specify_better_ico(time_at)
    puts "##{@thread_id} - specify_better_ico() at #{Time.now}"
    
    from = time_at - 2.hours.to_i

    query = """
      SELECT *
      FROM (
        SELECT pair_name, count(analysis_pump) as analysis_pump
        FROM bitfi_price_logs
        WHERE time_at > #{from} AND time_at < #{time_at}
        AND analysis_pump = 1 AND analysis_value > 0
        GROUP BY pair_name
      ) as tb
      ORDER BY analysis_pump DESC
    """

    # records_array = ActiveRecord::Base.connection.execute(query)
    records = ActiveRecord::Base.connection.exec_query(query)

    records.each do |record|
      pair_name = record["pair_name"]

      # Get max, min price
      from = time_at - 12.hours.to_i
      query = """
        SELECT pair_name, max(buy_price) as max_price, min(buy_price) as min_price
        FROM bitfi_price_logs
        WHERE time_at > #{from} AND time_at < #{time_at}
        AND pair_name = '#{pair_name}'
      """
      data = ActiveRecord::Base.connection.exec_query(query)
      max_price = data[0]["max_price"]
      min_price = data[0]["min_price"]

      # Get current price
      query = """
        SELECT *
        FROM bitfi_price_logs
        WHERE time_at <= #{time_at} and pair_name='#{pair_name}'
        ORDER BY id DESC
        LIMIT 1
      """
      data = ActiveRecord::Base.connection.exec_query(query)
      current_price = data[0]["sell_price"]
      percent = (current_price - min_price) / (max_price - min_price) * 100

      capa_percent = (max_price / min_price * 100 - 100)

      except_icos = ['RRTUSD']
      if percent <= 40 and capa_percent >= 6 and !except_icos.include? pair_name
        puts "\ncurrent: #{current_price} - min: #{min_price} - max: #{max_price}"
        puts "#{pair_name} count: #{record['analysis_pump']} - #{'%.2f' % percent}% - #{'%.2f' % capa_percent}"  
        puts "FIND A NEW ICO - #{pair_name} - #{'%.2f' % percent} - #{'%.2f' % capa_percent}"
        
        list = IcoBot.where(pair_name: pair_name)
        if list.length == 0
          puts "FIND A NEW ICO - #{pair_name} - #{'%.2f' % percent} - #{'%.2f' % capa_percent}"
          return pair_name
        else
          next
        end
      end
    end

    return nil
  end

  def check_set_order_for_buy    
    puts "##{@thread_id} - #{@ico_bot.pair_name} - check_set_order_for_buy() with price #{'%.8f' % @current_buy_price} at #{Time.now}"
    
    time_before = Time.now.to_i - 3.minutes.to_i
    before_price_log = BitfiPriceLog.where("pair_name = ? AND time_at > ?", @ico_bot.pair_name, time_before).order(id: 'ASC').first
    
    if @current_buy_price <= before_price_log.buy_price
      puts "##{@thread_id} - #{@ico_bot.pair_name} -> #{'%.8f' % @current_buy_price} < #{'%.8f' % before_price_log.buy_price} so return"
      return
    end
    
    if @price_log.analysis_pump == 1 and @price_log.change_buy_percent > 0.01 and @price_log.change_sell_percent > 0.01
      buy_price = @price_log.buy_price
      if @price_log.diff_price_percent <= 0.4
        buy_price = @price_log.sell_price
      else
        return
      end
      
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
  end

  def check_finish_order_buy
    puts "##{@thread_id} - #{@ico_bot.pair_name} - check_finish_order_buy() with price #{'%.8f' % @current_buy_price} at #{Time.now}"

    status = @api_obj.check_order(@current_order.buy_order_id)

    if status == 1
      @current_order.bought_order_id = 1
      @current_order.save

      # amount = @api_obj.get_balances(@ico_bot.ico_name)
      # @ico_bot.amount_ico = amount
      @ico_bot.trading_type = "SELLING"      
      @ico_bot.save!
    end
  end

  def check_set_order_sell    
    force_sell = true
    # @is_lose = false

    # time_before = Time.now.to_i - 1.5.minutes.to_i
    # before_price_log = BitfiPriceLog.where("pair_name = ? AND time_at > ?", @ico_bot.pair_name, time_before).order(id: 'ASC').first

    # profit = ((@current_buy_price - @current_order.buy_price) / @current_order.buy_price * 100).round(2)
    # puts "##{@thread_id} - #{@ico_bot.pair_name} - check_set_order_sell() with price #{'%.8f' % @current_buy_price} (#{'%.2f' % profit}) at #{Time.now}"

    # if @current_buy_price > before_price_log.buy_price
    #   puts "##{@thread_id} - #{@ico_bot.pair_name} -> #{'%.8f' % @current_buy_price} < #{'%.8f' % before_price_log.buy_price} still increase"
    #   return
    # end
    
    # if profit > 1 #and @price_log.change_buy_percent <= 0
    #   force_sell = true
    # end

    # if profit < -3
    #   force_sell = true
    #   # @is_lose = true
    # end

    if force_sell
      profit = 0.02 # 12%
      @current_order.sell_price = (@current_order.buy_price + @current_order.buy_price * profit).round(8)

      # profit = ((@current_order.sell_price - @current_order.buy_price) / @current_order.buy_price * 100).round(2)
      @current_order.profit = profit * 100

      amount = @api_obj.get_balances(@ico_bot.ico_name)
      @ico_bot.amount_ico = amount

      obj_sell = @api_obj.sell(@ico_bot.pair_name, @ico_bot.amount_ico, @current_order.sell_price)
      @current_order.sell_order_id = obj_sell['order_id']
      @current_order.save

      @ico_bot.trading_type = "CHECKING_ORDER_SELL"
      @ico_bot.save
    end
  end

  def check_finish_order_sell
    current_profit = (@current_sell_price - @current_order.buy_price) / @current_order.buy_price * 100
    puts "##{@thread_id} - #{@ico_bot.pair_name} - check_finish_order_sell() with price #{'%.8f' % @current_buy_price}(#{'%.2f' % current_profit}%) - #{'%.8f' % @current_order.sell_price}(#{'%.2f' % @current_order.profit}%) at #{Time.now}"

    status = @api_obj.check_order(@current_order.sell_order_id)

    if status == 1
      @current_order.sold_order_id = 1
      @current_order.save
      @ico_bot.trading_type = "DONE"
      @ico_bot.save

      sleep(60 * 2)
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

  def find_pump()
    # puts "#{@ico_bot.pair_name} - find_pump() - #{@price_log.id}"
    records = BitfiTradeLog.where("pair_name = ? AND time_at <= ?", @ico_bot.pair_name, @price_log.time_at).order(id: 'desc').limit(4)

    flag_all_active = true
    records.each do |record|
      if record.analysis_value < 0
        flag_all_active = false
        break
      end
    end

    if flag_all_active == true
      @price_log.analysis_pump = 1
    end

    @price_log.save!
  end

  def find_down()
    # puts "#{@ico_bot.pair_name} - find_down() - #{@price_log.id}"
    records = BitfiTradeLog.where("pair_name = ? AND time_at <= ?", @ico_bot.pair_name, @price_log.time_at).order(id: 'desc').limit(4)

    flag_all_active = true
    records.each do |record|
      if record.analysis_value > 0
        flag_all_active = false
        break
      end
    end

    if flag_all_active == true
      @price_log.analysis_pump = -1
    else
      @price_log.analysis_pump = 0
    end

    @price_log.save!
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
