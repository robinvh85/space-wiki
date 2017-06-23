require 'poloniex_vh'

namespace :chart_data do
  task get_init: :environment do
    puts "Run rake chart_data:get_init"

    PoloniexVh.setup do | config |
      config.key = 'KeyVVGCGL9G-5YV2M7RC-TCTCYIFX-QBHGLPX6'
      config.secret = '0c4496e534e874a8533756ff5121f3e5be4add3c60b985157d9cf325a742c5c74fac18b1262667577c079809b084fa279110563911bcfdf75439588b858f8a59'
    end

    CurrentOrder.delete_all
    currency_pairs = CurrencyPair.all
    currency_pairs.each do |currency_pair|
      [300, 900, 1800, 7200, 14400, 86400].each do |period|
        get_data_chart(currency_pair, period)
      end
    end
  end
end

def get_data_chart(currency_pair, period)
  puts "#{currency_pair.name} - period: #{period}"

  response = PoloniexVh.get_all_daily_exchange_rates(currency_pair.name, period)
  data = JSON.parse(response.body)

  data.each do |item|
    ChartData.create({
      currency_pair_id: currency_pair.id,
      date_time: Time.at(item['date']),
      time_at:  item['date'],
      high:     item['high'],
      low:      item['low'],
      open:     item['open'],
      close:    item['close'],
      volume:   item['volume'],
      weighted_average: item['weighted_average']
    })
  end
end
