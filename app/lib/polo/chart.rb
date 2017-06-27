require 'poloniex_vh'

module Polo
  class Chart

    PoloniexVh.setup do | config |
      config.key = 'VVGCGL9G-5YV2M7RC-TCTCYIFX-QBHGLPX6'
      config.secret = '0c4496e534e874a8533756ff5121f3e5be4add3c60b985157d9cf325a742c5c74fac18b1262667577c079809b084fa279110563911bcfdf75439588b858f8a59'
    end

    def self.get_current(pair)
      result = {}
      response = PoloniexVh.order_book(pair)
      data = JSON.parse(response.body)

      result['bid_orders'] = parse_orders(pair, data['bids'], 'bid')      
      result['ask_orders'] = parse_orders(pair, data['asks'], 'ask')

      result
    end
    
    def self.parse_orders(currency_pair, list, method)
      data = []

      accumulate_price = 0.0
      list.each do |item|
        total_price = item[0].to_f * item[1].to_f
        accumulate_price += total_price

        data.push({
          currency_pair: currency_pair,
          method: method,
          price: "%.8f" % item[0].to_f,
          amount: "%.8f" % item[1].to_f,
          total_price: "%.8f" % total_price,
          accumulate_price: "%.8f" % accumulate_price
        })
      end

      data
    end
  end  
end