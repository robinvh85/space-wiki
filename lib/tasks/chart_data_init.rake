require 'poloniex_vh'

PoloniexVh.setup do | config |
  config.key = 'KeyVVGCGL9G-5YV2M7RC-TCTCYIFX-QBHGLPX6'
  config.secret = '0c4496e534e874a8533756ff5121f3e5be4add3c60b985157d9cf325a742c5c74fac18b1262667577c079809b084fa279110563911bcfdf75439588b858f8a59'
end

namespace :chart_data_init do
  task :get, [:pair_name] => :environment do |_cmd, args|
    puts "Run rake chart_data_init:get for #{args[:pair_name]} at #{Time.now}"

    ChartDataYear.start = Time.new(2017, 9, 25).to_i
    ChartDataYear.end = Time.now.to_i

    # currency_pairs = CurrencyPair.where("name = ?", args[:pair_name])
    # currency_pairs = CurrencyPair.all if currency_pairs.count == 0

    if args[:pair_name].nil?
      currency_pairs = CurrencyPair.all
    else
      currency_pairs = CurrencyPair.where("name = ?", args[:pair_name])
    end

    currency_pairs.each do |currency_pair|
      # ChartDataYear.get_data_chart_30m(currency_pair)
      ChartDataYear.get_data_chart_4h(currency_pair)
      # ChartDataYear.get_data_chart_1d(currency_pair)
    end
  end
end

module ChartDataYear
  class << self
    attr_accessor :start, :end
    # 30m
    def get_data_chart_30m(currency_pair, period = 1800)
      puts "#{currency_pair.name} - period: #{period} at #{Time.now}"

      response = PoloniexVh.get_daily_exchange_rates(currency_pair.name, period, @start, @end)
      data = JSON.parse(response.body)

      data.each do |item|
        ChartData30m.create(build_data(currency_pair, item))
      end
    end

    def get_data_chart_4h(currency_pair, period = 14400)
      puts "#{currency_pair.name} - period: #{period} at #{Time.now}"

      response = PoloniexVh.get_daily_exchange_rates(currency_pair.name, period, @start, @end)
      data = JSON.parse(response.body)

      data.each do |item|
        ChartData4h.create(build_data(currency_pair, item))
      end
    end

    def get_data_chart_1d(currency_pair, period = 86400)
      puts "#{currency_pair.name} - period: #{period} at #{Time.now}"

      response = PoloniexVh.get_daily_exchange_rates(currency_pair.name, period, @start, @end)
      data = JSON.parse(response.body)

      data.each do |item|
        ChartData1d.create(build_data(currency_pair, item))
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