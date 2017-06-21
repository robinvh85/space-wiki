# require 'poloniex'
# require 'json'

namespace :orders do
  task get_current: :environment do
    puts "Run rake orders:get_current"

    Poloniex.setup do | config |
      config.key = 'KeyVVGCGL9G-5YV2M7RC-TCTCYIFX-QBHGLPX6'
      config.secret = '0c4496e534e874a8533756ff5121f3e5be4add3c60b985157d9cf325a742c5c74fac18b1262667577c079809b084fa279110563911bcfdf75439588b858f8a59'
    end

    currency_pair = 'USDT_LTC'
    response = Poloniex.order_book(currency_pair)
    data = JSON.parse(response.body)

    CurrentOrder.delete_all

    save_current_orders(currency_pair, data['bids'], 'bid')
    save_current_orders(currency_pair, data['asks'], 'ask')
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
      price: item[0].to_f,
      amount: item[1].to_f,
      total_price: total_price,
      accumulate_price: accumulate_price
    })
  end
end
