require 'poloniex_vh'

PoloniexVh.setup do | config |
  config.key = 'KeyVVGCGL9G-5YV2M7RC-TCTCYIFX-QBHGLPX6'
  config.secret = '0c4496e534e874a8533756ff5121f3e5be4add3c60b985157d9cf325a742c5c74fac18b1262667577c079809b084fa279110563911bcfdf75439588b858f8a59'
end

namespace :chart_data_init do
  task get: :environment do
    puts "Run rake chart_data:get_init"

    currency_pairs = CurrencyPair.all
    currency_pairs.each do |currency_pair|
      get_data_chart_5m(currency_pair)
      get_data_chart_15m(currency_pair)
      get_data_chart_30m(currency_pair)
      get_data_chart_2h(currency_pair)
      get_data_chart_4h(currency_pair)
      get_data_chart_1d(currency_pair)
    end
  end
end

# 5m
def get_data_chart_5m(currency_pair, period = 300)  
  puts "#{currency_pair.name} - period: #{period}"

  response = PoloniexVh.get_all_daily_exchange_rates(currency_pair.name, period)
  data = JSON.parse(response.body)

  data.each do |item|
    ChartData5m.create(build_data(currency_pair, item))
  end
end

# 15m
def get_data_chart_15m(currency_pair, period = 900)  
  puts "#{currency_pair.name} - period: #{period}"

  response = PoloniexVh.get_all_daily_exchange_rates(currency_pair.name, period)
  data = JSON.parse(response.body)

  data.each do |item|
    ChartData15m.create(build_data(currency_pair, item))
  end
end

# 30m
def get_data_chart_30m(currency_pair, period = 1800)  
  puts "#{currency_pair.name} - period: #{period}"

  response = PoloniexVh.get_all_daily_exchange_rates(currency_pair.name, period)
  data = JSON.parse(response.body)

  data.each do |item|
    ChartData30m.create(build_data(currency_pair, item))
  end
end

# 2h
def get_data_chart_2h(currency_pair, period = 7200)  
  puts "#{currency_pair.name} - period: #{period}"

  response = PoloniexVh.get_all_daily_exchange_rates(currency_pair.name, period)
  data = JSON.parse(response.body)

  data.each do |item|
    ChartData2h.create(build_data(currency_pair, item))
  end
end

# 4h
def get_data_chart_4h(currency_pair, period = 14400)  
  puts "#{currency_pair.name} - period: #{period}"

  response = PoloniexVh.get_all_daily_exchange_rates(currency_pair.name, period)
  data = JSON.parse(response.body)

  data.each do |item|
    ChartData4h.create(build_data(currency_pair, item))
  end
end

# 1d
def get_data_chart_1d(currency_pair, period = 86400)  
  puts "#{currency_pair.name} - period: #{period}"

  response = PoloniexVh.get_all_daily_exchange_rates(currency_pair.name, period)
  data = JSON.parse(response.body)

  data.each do |item|
    ChartData1d.create(build_data(currency_pair, item))
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
