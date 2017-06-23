require 'poloniex_vh'

PoloniexVh.setup do | config |
  config.key = 'KeyVVGCGL9G-5YV2M7RC-TCTCYIFX-QBHGLPX6'
  config.secret = '0c4496e534e874a8533756ff5121f3e5be4add3c60b985157d9cf325a742c5c74fac18b1262667577c079809b084fa279110563911bcfdf75439588b858f8a59'
end

@start = 0
@end = 0

namespace :chart_data do
  task get: :environment do
    puts "Run rake chart_data:get"

    sleep(5)
    @start = (Time.now - 10.minutes).to_i
    @end = Time.now.to_i

    currency_pairs = CurrencyPair.all
    currency_pairs.each do |currency_pair|
      ChartData.get_data_chart_5m(currency_pair)
      # ChartData.get_data_chart_15m(currency_pair)
      # ChartData.get_data_chart_30m(currency_pair)
      # ChartData.get_data_chart_2h(currency_pair)
      # ChartData.get_data_chart_4h(currency_pair)
      # ChartData.get_data_chart_1d(currency_pair)
    end
  end
end

module ChartData
  # 5m
  def self.get_data_chart_5m(currency_pair, period = 300)  
    puts "#{currency_pair.name} - period: #{period}"

    response = PoloniexVh.get_daily_exchange_rates(currency_pair.name, period, @start, @end)
    data = JSON.parse(response.body)

    data.each do |item|
      ChartData5m.create(self.build_data(currency_pair, item))
    end
  end

  # 15m
  def self.get_data_chart_15m(currency_pair, period = 900)  
    puts "#{currency_pair.name} - period: #{period}"

    response = PoloniexVh.get_daily_exchange_rates(currency_pair.name, period, @start, @end)
    data = JSON.parse(response.body)

    data.each do |item|
      ChartData15m.create(self.build_data(currency_pair, item))
    end
  end

  # 30m
  def self.get_data_chart_30m(currency_pair, period = 1800)  
    puts "#{currency_pair.name} - period: #{period}"

    response = PoloniexVh.get_daily_exchange_rates(currency_pair.name, period, @start, @end)
    data = JSON.parse(response.body)

    data.each do |item|
      ChartData30m.create(self.build_data(currency_pair, item))
    end
  end

  # 2h
  def self.get_data_chart_2h(currency_pair, period = 7200)  
    puts "#{currency_pair.name} - period: #{period}"

    response = PoloniexVh.get_daily_exchange_rates(currency_pair.name, period, @start, @end)
    data = JSON.parse(response.body)

    data.each do |item|
      ChartData2h.create(self.build_data(currency_pair, item))
    end
  end

  # 4h
  def self.get_data_chart_4h(currency_pair, period = 14400)  
    puts "#{currency_pair.name} - period: #{period}"

    response = PoloniexVh.get_daily_exchange_rates(currency_pair.name, period, @start, @end)
    data = JSON.parse(response.body)

    data.each do |item|
      ChartData4h.create(self.build_data(currency_pair, item))
    end
  end

  # 1d
  def self.get_data_chart_1d(currency_pair, period = 86400)  
    puts "#{currency_pair.name} - period: #{period}"

    response = PoloniexVh.get_daily_exchange_rates(currency_pair.name, period, @start, @end)
    data = JSON.parse(response.body)

    data.each do |item|
      ChartData1d.create(self.build_data(currency_pair, item))
    end
  end

  def self.build_data(currency_pair, item)
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
