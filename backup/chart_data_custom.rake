require 'poloniex_vh'

PoloniexVh.setup do | config |
  config.key = 'KeyVVGCGL9G-5YV2M7RC-TCTCYIFX-QBHGLPX6'
  config.secret = '0c4496e534e874a8533756ff5121f3e5be4add3c60b985157d9cf325a742c5c74fac18b1262667577c079809b084fa279110563911bcfdf75439588b858f8a59'
end

namespace :chart_data_custom do
  task :get, [:days] => :environment do |_cmd, args|
    puts "Run rake chart_data:get at #{Time.now} - Before day: #{args[:days]}"

    ChartData.start = (Time.now - args[:days].to_i.days).to_i
    ChartData.end = Time.now.to_i

    currency_pairs = CurrencyPair.where(is_init: 1)
    currency_pairs.each do |currency_pair|
      ChartData.get_data_chart_5m(currency_pair)
      ChartData.get_data_chart_15m(currency_pair)
      ChartData.get_data_chart_30m(currency_pair)
      ChartData.get_data_chart_2h(currency_pair)
      ChartData.get_data_chart_4h(currency_pair)
      ChartData.get_data_chart_1d(currency_pair)
    end

    puts "End rake chart_data:get at #{Time.now}"
  end
end

module ChartData
  class << self
    attr_accessor :start, :end

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

    # 4h
    def get_data_chart_4h(currency_pair, period = 14400)  
      puts "#{currency_pair.name} - period: #{period}"

      response = PoloniexVh.get_daily_exchange_rates(currency_pair.name, period, @start, @end)
      data = JSON.parse(response.body)

      data.each do |item|
        insert_or_update(currency_pair, item, ChartData4h)
      end
    end

    # 1d
    def get_data_chart_1d(currency_pair, period = 86400)  
      puts "#{currency_pair.name} - period: #{period}"

      response = PoloniexVh.get_daily_exchange_rates(currency_pair.name, period, @start, @end)
      data = JSON.parse(response.body)

      data.each do |item|
        insert_or_update(currency_pair, item, ChartData1d)
      end
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
