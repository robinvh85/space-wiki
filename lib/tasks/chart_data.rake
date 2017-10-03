require 'poloniex_vh'

PoloniexVh.setup do | config |
  config.key = 'KeyVVGCGL9G-5YV2M7RC-TCTCYIFX-QBHGLPX6'
  config.secret = '0c4496e534e874a8533756ff5121f3e5be4add3c60b985157d9cf325a742c5c74fac18b1262667577c079809b084fa279110563911bcfdf75439588b858f8a59'
end

namespace :chart_data do
  task get: :environment do
    puts "Run rake chart_data:get at #{Time.now}"

    sleep(2)
    # ChartData.start = (Time.now - 1.hours).to_i
    # ChartData.end = Time.now.to_i

    currency_pairs = CurrencyPair.where(is_disabled: 0)
    currency_pairs.each do |currency_pair|
      ChartData.update_previous_price(currency_pair.name)

      ChartData.get_data_chart_30m(currency_pair)
      ChartData.get_data_chart_4h(currency_pair)
      ChartData.get_data_chart_1d(currency_pair)
    end

    puts "End rake chart_data:get at #{Time.now}"
  end
end

module ChartData
  class << self
    attr_accessor :start, :end

    def update_previous_price(pair_name)
      puts "update_previous_price() #{pair_name} at #{Time.now}"      

      ico_info = IcoInfo.find_by(pair_name: pair_name)
      return if ico_info.nil?

      # price_1d
      yesterday = Time.now - 1.days
      yesterday_time = Time.new(yesterday.year, yesterday.month, yesterday.day, 0, 0, 0)
      price_1d = ChartData1d.find_by(pair_name: pair_name, time_at: yesterday_time)

      # price 4h
      previous_4h = Time.now - 4.hours
      arr_hours = [0,4,8,12,16,20]
      hour = arr_hours[previous_4h.hour / 4]

      previous_4h_time = Time.new(previous_4h.year, previous_4h.month, previous_4h.day, hour, 0, 0)
      price_4h = ChartData4h.find_by(pair_name: pair_name, time_at: previous_4h_time)

      # price 30m
      previous_30m = Time.now - 30.minutes

      arr_minutes = [0,30]
      minute = arr_minutes[previous_30m.min / 30]

      previous_30m_time = Time.new(previous_30m.year, previous_30m.month, previous_30m.day, previous_30m.hour, minute, 0)
      price_30m = ChartData30m.find_by(pair_name: pair_name, time_at: previous_30m_time)

      ico_info.previous_30m_price = price_30m.close if !price_30m.nil? && price_30m['date'] != 0
      ico_info.previous_4h_price = price_4h.close if !price_4h.nil? && price_4h['date'] != 0
      ico_info.previous_1d_price = price_1d.close if !price_1d.nil? && price_1d['date'] != 0
      ico_info.save
    end

    # 30m
    def get_data_chart_30m(currency_pair, period = 1800)
      puts "#{currency_pair.name} - period: #{period} at #{Time.now}"

      start_time = (Time.now - 1.hours).to_i
      end_time = Time.now.to_i

      response = PoloniexVh.get_daily_exchange_rates(currency_pair.name, period, start_time, end_time)
      data = JSON.parse(response.body)

      data.each do |item|
        insert_or_update(currency_pair, item, ChartData30m)
      end
    end

    # 4h
    def get_data_chart_4h(currency_pair, period = 14400)
      puts "#{currency_pair.name} - period: #{period}"

      start_time = (Time.now - 4.hours).to_i
      end_time = Time.now.to_i

      response = PoloniexVh.get_daily_exchange_rates(currency_pair.name, period, start_time, end_time)
      data = JSON.parse(response.body)

      data.each do |item|
        insert_or_update(currency_pair, item, ChartData4h)
      end
    end

    # 1d
    def get_data_chart_1d(currency_pair, period = 86400)
      puts "#{currency_pair.name} - period: #{period} at #{Time.now}"

      start_time = (Time.now - 1.days).to_i
      end_time = Time.now.to_i

      response = PoloniexVh.get_daily_exchange_rates(currency_pair.name, period, start_time, end_time)
      data = JSON.parse(response.body)

      data.each do |item|
        insert_or_update(currency_pair, item, ChartData1d)
      end
    end

    def insert_or_update(currency_pair, data_item, chart_data_class)
      chart_data_obj = chart_data_class.find_by("pair_name = ? AND time_at = ?", currency_pair.name, data_item['date'])
      if chart_data_obj.nil?
        chart_data_class.create(build_data(currency_pair, data_item))
      else
        chart_data_class.update(chart_data_obj.id, build_data(currency_pair, data_item))
      end
    end

    def build_data(currency_pair, item)
      {
        pair_name: currency_pair.name,
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
