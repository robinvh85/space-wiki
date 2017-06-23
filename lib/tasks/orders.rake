require 'poloniex_vh'

namespace :orders do
  task get_current: :environment do
    puts "Run rake orders:get_current"

    PoloniexVh.setup do | config |
      config.key = 'KeyVVGCGL9G-5YV2M7RC-TCTCYIFX-QBHGLPX6'
      config.secret = '0c4496e534e874a8533756ff5121f3e5be4add3c60b985157d9cf325a742c5c74fac18b1262667577c079809b084fa279110563911bcfdf75439588b858f8a59'
    end

    CurrentOrder.delete_all
    currency_pairs = CurrencyPair.all
    currency_pairs.each do |currency_pair|
      currency_pair_name = currency_pair.name
      response = PoloniexVh.order_book(currency_pair_name)
      data = JSON.parse(response.body)
      save_current_orders(currency_pair_name, data['bids'], 'bid')
      save_current_orders(currency_pair_name, data['asks'], 'ask')
    end
  end
end

def save_current_orders(currency_pair, list, method)
  accumulate_price = 0.0
  list.each do |item|
    total_price = item[0].to_f * item[1].to_f
    accumulate_price += total_price

    CurrentOrder.create({
      currency_pair: currency_pair,
      method: method,
      price: "%.8f" % item[0].to_f,
      amount: "%.8f" % item[1].to_f,
      total_price: "%.8f" % total_price,
      accumulate_price: "%.8f" % accumulate_price
    })
  end
end
