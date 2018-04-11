
namespace :ico_bot_finding_buy do
  task :start, [] => :environment do |_cmd, args|
    puts "Run rake ico_bot_finding_buy:start"
    
    cycle_time = 20
    pair_names = ['BCHUSD', 'USDT_BCH']

    finding_objs = []
    # init obj
    pair_names.each do |pair_name|
      finding_obj = FindingBuyBasic.new({pair_name: pair_name})
      finding_objs << finding_obj
    end

    while true
      start_time = Time.now

      finding_objs.each do |finding_obj|
        finding_obj.finding()
        sleep(0.2)
      end

      end_time = Time.now
      inteval = (end_time - start_time).to_i

      sleep(cycle_time - inteval) if cycle_time - inteval > 0
    end
  end
end

class FindingBuyBasic
  def initialize(config)
    @pair_name = config[:pair_name]
    @bot = IcoBot.find_by(pair_name: @pair_name)
  end

  def finding
    puts "#{@pair_name} - Find buy price at #{Time.now}"

    @bot.reload
    return if @bot.trading_type != 'DONE'
    return if @bot.current_buy_price > @bot.buy_price

    ico_price = IcoPriceLog.where(pair_name: @pair_name).last

    puts "#{@pair_name} - change percent: #{ico_price.change_buy_percent} - analysis_value: #{ico_price.analysis_value}"

    if ico_price.analysis_value > 0.2 && ico_price.change_buy_percent > 0.02
      puts "#{@pair_name} - set BUY with percent #{ico_price.change_buy_percent}"
      @bot.trading_type = 'FORCE_BUY'
      @bot.status = 1
      # @bot.buy_price = @bot.current_buy_price + @bot.current_buy_price * 0.003
      # @bot.sell_price = @bot.buy_price + @bot.buy_price * 0.05
      @bot.save!
    end
  end
end

class FindingBuy
  def initialize(config)
    @pair_name = config[:pair_name]
    @bot = IcoBot.find_by(pair_name: @pair_name)
  end

  def finding
    if @pair_name == 'BCHUSD'
      finding_bchusd()
    elsif @pair_name == 'USDT_BCH'
      finding_usdt_bch()
    end
  end

  def finding_bchusd
    puts "#{@pair_name} - Find buy price at #{Time.now}"

    url = "https://api.bitfinex.com/v2/candles/trade:5m:t#{@pair_name}/hist?limit=2"
    @bot.reload
    return if @bot.trading_type != 'DONE'

    ico_price = IcoPriceLog.where(pair_name: @pair_name).last
    puts "#{@pair_name} - change percent: #{ico_price.change_buy_percent}"
    return if ico_price.change_buy_percent < 1

    candles = JSON.parse(`curl #{url}`)
    candles[-1]

    previous_candle = {
      open: candles[-1][1],
      close: candles[-1][2],
      high: candles[-1][3],
      low: candles[-1][4],
    }

    if previous_candle[:close] < previous_candle[:open] # If down
      puts "#{@pair_name} - set BUY with percent #{ico_price.change_buy_percent}"
      @bot.trading_type = 'FORCE_BUY'
      @bot.status = 1
      @bot.buy_price = @bot.current_buy_price + @bot.current_buy_price * 0.003
      @bot.sell_price = @bot.buy_price + @bot.buy_price * 0.05
      @bot.save!
    end
  end

  def finding_usdt_bch
    puts "#{@pair_name} - Find buy price at #{Time.now}"

    @bot.reload
    return if @bot.trading_type != 'DONE'

    return if @bot.current_buy_price > @bot.limit_price_for_buy

    ico_price = IcoPriceLog.where(pair_name: @pair_name).last
    puts "#{@pair_name} - change percent: #{ico_price.change_buy_percent}"
    return if ico_price.change_buy_percent < 1

    previous_candle = ChartData5m.where(currency_pair_id: 12).last

    if previous_candle.close < previous_candle.open # If down
      puts "#{@pair_name} - set BUY with percent #{ico_price.change_buy_percent}"
      @bot.trading_type = 'FORCE_BUY'
      @bot.status = 1
      @bot.buy_price = @bot.current_buy_price + @bot.current_buy_price * 0.003
      @bot.sell_price = @bot.buy_price + @bot.buy_price * 0.05
      @bot.save!
    end
  end
end
