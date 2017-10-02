require 'poloniex_vh'

PoloniexVh.setup do | config |
  config.key = 'KeyVVGCGL9G-5YV2M7RC-TCTCYIFX-QBHGLPX6'
  config.secret = '0c4496e534e874a8533756ff5121f3e5be4add3c60b985157d9cf325a742c5c74fac18b1262667577c079809b084fa279110563911bcfdf75439588b858f8a59'
end

namespace :chart_data do
  task get: :environment do
    puts "Run rake chart_data:get at #{Time.now}"

    sleep(2)
    ChartData.start = (Time.now - 1.hours).to_i
    ChartData.end = Time.now.to_i

    currency_pairs = CurrencyPair.where(is_disabled: 0)
    currency_pairs.each do |currency_pair|
      ChartData.get_data_chart_30m(currency_pair)
      ChartData.get_data_chart_1d(currency_pair)

      ChartData.update_yesterday_price(currency_pair.name)
    end

    puts "End rake chart_data:get at #{Time.now}"
  end
end

module ChartData
  class << self
    attr_accessor :start, :end

    def update_yesterday_price(pair_name)
      puts "Update yesterday_price #{pair_name}"
      yesterday = Time.now - 1.days
      yesterday_time = Time.new(yesterday.year, yesterday.month, yesterday.day, 0, 0, 0)

      price_1d = ChartData1d.find_by(pair_name: pair_name, time_at: yesterday_time)

      return if price_1d.nil?

      ico_info = IcoInfo.find_by(pair_name: pair_name)

      unless ico_info.nil?
        ico_info.yesterday_price = price_1d.close
        ico_info.save!
      end
    end

    # 30m
    def get_data_chart_30m(currency_pair, period = 1800)
      puts "#{currency_pair.name} - period: #{period} at #{Time.now}"

      response = PoloniexVh.get_daily_exchange_rates(currency_pair.name, period, @start, @end)
      data = JSON.parse(response.body)

      data.each do |item|
        insert_or_update(currency_pair, item, ChartData30m)
      end
    end

    # 1d
    def get_data_chart_1d(currency_pair, period = 86400)
      puts "#{currency_pair.name} - period: #{period} at #{Time.now}"

      response = PoloniexVh.get_daily_exchange_rates(currency_pair.name, period, @start, @end)
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
