# 
namespace :bitfi_get_price do
  task :start, [] => :environment do |_cmd, args|
    puts "Run rake bitfi_get_price:start"
    
    cycle_time = 20

    thread_num = 2
    api_obj_hash = {}
    threads = []

    account = IcoAccount.find(1)
    api_obj = Bitfi.new({
      key: account.key,
      secret: account.secret
    })

    # Init api_obj_hash
    pair_list_origin = [
      ["ETHUSD", "BCHUSD", "LTCUSD", "XRPUSD", "IOTUSD", "XMRUSD", "RRTUSD"],   
      ["EOSUSD", "DSHUSD", "ZECUSD", "BTCUSD", "ETCUSD", "OMGUSD", "SANUSD"]
      # ["XRPUSD", "SANUSD"],   
      # ["XMRUSD"]
    ]

    # Create threads
    thread_num.times do |index|
      puts "Create thread ##{index + 1}"
      thread = Thread.new{
        thread_id = index + 1
        pair_list = pair_list_origin[index]
        ico_list = []

        # init objs
        pair_list.each do |pair|
          ico_list << BitfiPrice.new({
            thread_id: thread_id,
            pair: pair,
            api_obj: api_obj
          })
        end

        while true
          start_time = Time.now
          puts "\n#{thread_id} run at #{Time.now}"
          ico_list.each do |ico|
            puts "#{thread_id} - #{ico.pair}"

            ico.update_current_price()
            price_log = ico.save_price()

            next if price_log.nil?

            ico.find_pump(price_log)
            ico.find_down(price_log) if price_log.analysis_pump != 1

            sleep(0.3)
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

class BitfiPrice
  attr_accessor :pair

  def initialize(config)
    @thread_id = config[:thread_id]
    @pair = config[:pair]
    @api_obj = config[:api_obj]

    @previous_buy_price = 0
    @previous_sell_price = 0
    @current_buy_price = 0
    @current_sell_price = 0
  end

  def update_current_price
    # Backup previous price
    @previous_sell_price = @current_sell_price
    @previous_buy_price = @current_buy_price

    # Get new price    
    data = @api_obj.get_current_trading_price(@pair, 0)

    return nil if data.nil?

    @current_buy_price  = data[:buy_price]
    @current_sell_price = data[:sell_price]
  end

  def save_price
    return nil if @previous_buy_price == 0

    puts "##{@thread_id} - #{@pair} - save_price() at #{Time.now}"
    change_buy_percent = ((@current_buy_price - @previous_buy_price) / @previous_buy_price * 100).round(2)
    change_sell_percent = ((@current_sell_price - @previous_sell_price) / @previous_sell_price * 100).round(2)
    diff_price_percent = ((@current_sell_price - @current_buy_price) / @current_buy_price * 100).round(2)

    time_at = Time.now.to_i
    records = BitfiPriceLog.where("pair_name = ? AND time_at <= ?", @pair, time_at).order(id: 'desc').limit(4)
    analysis_value = change_buy_percent
    
    records.each do |record|
      analysis_value += record.change_buy_percent
    end

    price_log = BitfiPriceLog.new({
      pair_name: @pair,
      buy_price: @current_buy_price,
      sell_price: @current_sell_price,
      change_buy_percent: change_buy_percent,
      change_sell_percent: change_sell_percent,
      diff_price_percent: diff_price_percent,
      period_type: '20s',
      analysis_value: analysis_value,
      time_at: time_at
    })
    
    price_log.save!
    price_log
  end

  def find_pump(price_log)
    puts "#{@pair} - find_pump() - #{price_log.id}"
    records = BitfiPriceLog.where("pair_name = ? AND time_at <= ?", @pair, price_log.time_at).order(id: 'desc').limit(4)

    flag_all_active = true
    records.each do |record|
      if record.analysis_value < 0
        flag_all_active = false
        break
      end
    end

    if flag_all_active == true
      price_log.analysis_pump = 1
    end

    price_log.save!
  end

  def find_down(price_log)
    puts "#{@pair} - find_down() - #{price_log.id}"
    records = BitfiPriceLog.where("pair_name = ? AND time_at <= ?", @pair, price_log.time_at).order(id: 'desc').limit(4)

    flag_all_active = true
    records.each do |record|
      if record.analysis_value > 0
        flag_all_active = false
        break
      end
    end

    if flag_all_active == true
      price_log.analysis_pump = -1
    else
      price_log.analysis_pump = 0
    end

    price_log.save!
  end
end