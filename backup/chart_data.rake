require 'poloniex_vh'

PoloniexVh.setup do | config |
  config.key = 'KeyVVGCGL9G-5YV2M7RC-TCTCYIFX-QBHGLPX6'
  config.secret = '0c4496e534e874a8533756ff5121f3e5be4add3c60b985157d9cf325a742c5c74fac18b1262667577c079809b084fa279110563911bcfdf75439588b858f8a59'
end

namespace :chart_data do
  task get: :environment do
    puts "Run rake chart_data:get at #{Time.now}"

    sleep(2)
    ChartData.start = (Time.now - 10.minutes).to_i
    ChartData.end = Time.now.to_i

    currency_pairs = CurrencyPair.where(is_init: 1)
    currency_pairs.each do |currency_pair|
      ChartData.get_data_chart_5m(currency_pair)
      ChartData.get_percent_min_24h(currency_pair)
      
      # ChartData.get_data_chart_15m(currency_pair)
      # ChartData.get_percent_min_15m_24h(currency_pair)

      # ChartData.get_data_chart_30m(currency_pair)
      # ChartData.get_percent_min_30m_24h(currency_pair)
      
      # ChartData.get_data_chart_2h(currency_pair)
    end

    ChartData.get_increase_percent()

    puts "End rake chart_data:get at #{Time.now}"
  end

  task get1: :environment do
    ChartData.get_increase_percent()
  end
end

module ChartData
  class << self
    attr_accessor :start, :end

    def get_increase_percent
      date = Time.now.strftime("%Y/%m/%d")

      CurrencyPair.where(is_init: 1).each do |current_pair|
        puts "#{current_pair.name} - Get start_percent_min for #{date} at #{Time.now}"

        sample_data = ChartData5m.find_by("currency_pair_id = ? AND date_time > ?", current_pair.id, date)

        data_5m = ChartData5m.where(currency_pair_id: current_pair.id).last
        data_5m.increase_percent = ((data_5m.min_value - sample_data.min_value) / sample_data.min_value * 100).round(4)
        data_5m.save!
      end
    end

    # 5m
    def get_data_chart_5m(currency_pair, period = 300)  
      puts "#{currency_pair.name} - period: #{period}"

      response = PoloniexVh.get_daily_exchange_rates(currency_pair.name, period, @start, @end)
      data = JSON.parse(response.body)

      data.each do |item|
        insert_or_update(currency_pair, item, ChartData5m)
      end
    end

    # 15m
    def get_data_chart_15m(currency_pair, period = 900)  
      puts "#{currency_pair.name} - period: #{period}"

      response = PoloniexVh.get_daily_exchange_rates(currency_pair.name, period, @start, @end)
      data = JSON.parse(response.body)

      data.each do |item|
        insert_or_update(currency_pair, item, ChartData15m)
      end
    end

    # 30m
    def get_data_chart_30m(currency_pair, period = 1800)  
      puts "#{currency_pair.name} - period: #{period}"

      response = PoloniexVh.get_daily_exchange_rates(currency_pair.name, period, @start, @end)
      data = JSON.parse(response.body)

      data.each do |item|
        insert_or_update(currency_pair, item, ChartData30m)
      end
    end

    # 2h
    def get_data_chart_2h(currency_pair, period = 7200)  
      puts "#{currency_pair.name} - period: #{period}"

      response = PoloniexVh.get_daily_exchange_rates(currency_pair.name, period, @start, @end)
      data = JSON.parse(response.body)

      data.each do |item|
        insert_or_update(currency_pair, item, ChartData2h)
      end
    end

    def get_percent_min_24h(currency_pair)
      list = ChartData5m.where("currency_pair_id = ? AND time_at >= ?", currency_pair.id, @start)
      index = 0
      list.each do |item|
        index += 1
        if item.close < item.open
          item.min_value = item.close
        else
          item.min_value = item.open
        end
        item.save
      end

      list = ChartData5m.where("currency_pair_id = ? AND time_at >= ?", currency_pair.id, @start)
      index = 0
      list.each do |item|
        index += 1
        _end = Time.at(item.time_at).to_i
        start = (_end - 24.hour).to_i

        min = ChartData5m.where("currency_pair_id = ? AND time_at > ? AND time_at <= ?", currency_pair.id, start, _end).minimum(:min_value)
        max = ChartData5m.where("currency_pair_id = ? AND time_at > ? AND time_at <= ?", currency_pair.id, start, _end).maximum(:min_value)

        currency_pair.percent_min_24h = (item.min_value - min) / (max - min) * 100
        currency_pair.save
      end
    end

    def get_percent_min_15m_24h(currency_pair)
      list = ChartData15m.where("currency_pair_id = ? AND time_at >= ?", currency_pair.id, @start)
      index = 0
      list.each do |item|
        index += 1
        if item.close < item.open
          item.min_value = item.close
        else
          item.min_value = item.open
        end
        item.save
      end

      list = ChartData15m.where("currency_pair_id = ? AND time_at >= ?", currency_pair.id, @start)
      index = 0
      list.each do |item|
        index += 1
        _end = Time.at(item.time_at).to_i
        start = (_end - 24.hour).to_i

        min = ChartData15m.where("currency_pair_id = ? AND time_at > ? AND time_at <= ?", currency_pair.id, start, _end).minimum(:min_value)
        max = ChartData15m.where("currency_pair_id = ? AND time_at > ? AND time_at <= ?", currency_pair.id, start, _end).maximum(:min_value)

        currency_pair.percent_min_24h = (item.min_value - min) / (max - min) * 100
        currency_pair.save
      end
    end

    def get_percent_min_30m_24h(currency_pair)
      list = ChartData30m.where("currency_pair_id = ? AND time_at >= ?", currency_pair.id, @start)
      list.each do |item|
        if item.close < item.open
          item.min_value = item.close
        else
          item.min_value = item.open
        end
        item.save
      end

      # list = ChartData30m.where("currency_pair_id = ? AND time_at >= ?", currency_pair.id, @start)
      # index = 0
      # list.each do |item|
      #   index += 1
      #   _end = Time.at(item.time_at).to_i
      #   start = (_end - 24.hour).to_i

      #   min = ChartData30m.where("currency_pair_id = ? AND time_at > ? AND time_at <= ?", currency_pair.id, start, _end).minimum(:min_value)
      #   max = ChartData30m.where("currency_pair_id = ? AND time_at > ? AND time_at <= ?", currency_pair.id, start, _end).maximum(:min_value)

      #   currency_pair.percent_min_24h = (item.min_value - min) / (max - min) * 100
      #   currency_pair.save
      # end
    end

    def insert_or_update(currency_pair, data_item, chart_data_class)
      chart_data_obj = chart_data_class.find_by("currency_pair_id = ? AND time_at = ?", currency_pair.id, data_item['date'])
      if chart_data_obj.nil?
        chart_data_class.create(build_data(currency_pair, data_item))
      else
        chart_data_class.update(chart_data_obj.id, build_data(currency_pair, data_item))
      end
    end

    def build_data(currency_pair, item)
      {
        currency_pair_id: currency_pair.id,
        date_time: Time.at(item['date']),
        time_at:  item['date'],
        high:     item['high'],
        low:      item['low'],
        open:     item['open'],
        close:    item['close'],
        volume:   item['volume'],
        quote_volume:   item['quoteVolume'],
        weighted_average: item['weightedAverage']
      }
    end
  end
end
