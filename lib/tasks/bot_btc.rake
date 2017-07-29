# 
namespace :bot_btc do
  task :start, [] => :environment do |_cmd, args|
    puts "Run rake bot_btc:start"
    
    cycle_time = 15
    trade_amount = 5

    config = {
      amount: 0.001
    }
    bot1 = BotBtc.new(config)

    while true
      start_time = Time.now
      result = {}
      
      bot1.update_current_price()
      bot1.analysis()

      end_time = Time.now
      inteval = (end_time - start_time).to_i

      sleep(cycle_time - inteval) if cycle_time - inteval > 0

      if bot1.finish_trade
        sleep(60 * 5) # delay 5m
        bot1.finish_trade = false
        
        trade_amount =- 1
        if trade_amount < 0
          break
        end
      end
    end
  end

class BotBtc
  attr_accessor :finish_trade
  
  def initialize(config)
    @trading_type = 'SELLING'
    @amount = config[:amount] # amount of BTC use to run
    @current_buy_price = 0
    @current_sell_price = 0
    @previous_buy_price = 0
    @previous_sell_price = 0
    @sell_price_list = []
    @buy_price_list = []
    @limit_amount_price_list = 5
    @limit_active_sell_percent = 0.15
    @limit_active_buy_percent = 0.15
    @limit_profit_for_buy = 1
    @limit_profit_force_buy = 1

    @is_active_sell = false
    @is_active_buy = false
    @btc_pair_id = 4
    @btc_pair_name = 'USDT_BTC'
    @current_order = nil
    @finish_trade = false
  end

  # def change_buy_percent
  #   if @previous_buy_price == 0
  #     0.0
  #   else 
  #     ((@current_buy_price - @previous_buy_price) / @previous_buy_price * 100).round(2)).to_f
  #   end
  # end

  # def change_sell_percent
  #   if @previous_sell_price == 0
  #     0.0
  #   else 
  #     ((@current_sell_price - @previous_sell_price) / @previous_sell_price * 100).round(2)).to_f
  #   end
  # end

  # Method

  # Can create many algorithms and watching for better
  def analysis
    return 0 if @previous_buy_price == 0 # next for the first time

    if @trading_type == "BUYING"
      analysis_for_buy()
    elsif @trading_type == "SELLING"
      analysis_for_sell()
    end    
  end
  
  def analysis_for_buy
    # @sell_price_list << change_sell_percent
    # @sell_price_list.shift if @sell_price_list.length > @limit_amount_price_list

    chart_data = ChartData5m.where(currency_pair_id: @btc_pair_id).last
    open_price = chart_data.open

    profit = (@current_order.sell_price - @current_sell_price) / @current_sell_price * 100

    if(@current_sell_price > open_price and (profit > @limit_profit_for_buy or -profit > @limit_profit_force_buy ))
      result = ApiBtc.buy(@amount, @current_sell_price)

      @current_order.buy_order_id = result['orderNumber']
      @current_order.bought_order_id = 1
      @current_order.buy_price = @current_sell_price
      @current_order.profit = profit
      @current_order.save
    
      @trading_type = "SELLING"
      @finish_trade = true
      @current_order = nil
    end

  end

  def analysis_for_sell
    # @sell_price_list << change_buy_percent
    # @sell_price_list.shift if @sell_price_list.length > @limit_amount_price_list

    # # TODO - check dieu kien de sell

    # unless @is_active_sell
    #   if -change_buy_percent > @limit_active_sell_percent
    #     @is_active_sell = true
    #     return
    #   end
    # end

    # if @is_active_sell
      
    # end

    chart_data = ChartData5m.where(currency_pair_id: @btc_pair_id).last
    close_price = chart_data.close

    if(@current_buy_price < close_price)
      obj_sell = ApiBtc.sell(@amount, @current_buy_price)
      
      @current_order = OrderBtc.create({
        sell_price: @current_buy_price,
        amount: @amount,
        sell_order_id: obj_sell['orderNumber'],
        sold_order_id: 1
      })
      
      @trading_type = "BUYING"
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
      
      puts "======> BUY FINISH at price: #{'%.8f' % price} - amount: #{amount}"
      result
    end

    def sell(amount, price)
      puts "====> Sell Amount: #{amount} with Price: #{'%.8f' % price} at #{Time.now}"
      result = JSON.parse(`python script/python/sell.py #{@pair_name} #{'%.8f' % price} #{amount}`)

      puts "======> SELL FINISH at price: #{'%.8f' % price} - amount: #{amount}"
      # if result["resultingTrades"].length > 0
      #   trade = result["resultingTrades"][0]
      #   puts "=======> SELL FINISH with Price: #{'%.8f' % price} at #{Time.now}"
      #   result
      # else
      #   false
      # end
      result
    end
  end
end
