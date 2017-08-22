class PoloObj
  def initialize()
  end

  def get_current_trading_price(pair_name, limit_amount)
    result = nil

    begin
      response = PoloniexVh.order_book(pair_name)
      data = JSON.parse(response.body)
      buy_price = 0
      data['bids'].each do |bid|
        if bid[1].to_f > limit_amount
          buy_price = bid[0].to_f
          break
        end
      end

      sell_price = 0
      data['asks'].each do |ask|
        if ask[1].to_f > limit_amount
          sell_price = ask[0].to_f
          break
        end
      end

      result = {
        buy_price: buy_price,
        sell_price: sell_price
      }
    rescue Exception => e
      puts "Error #{e}"
    end

    result
  end

  def buy(pair_name, amount, price)
    puts "====> Buy with Amount: #{amount} at Price: #{'%.8f' % price} at #{Time.now}"
    result = nil

    begin
      order = JSON.parse(`python -W ignore script/python/buy.py #{pair_name} #{'%.8f' % price} #{amount}`)
      result = {"order_id" => order["orderNumber"]}
      puts "======> BUY FINISH at price: #{'%.8f' % price} - amount: #{amount}"
    rescue Exception => e
      puts "BUY ERROR #{e}"
    end

    result
  end

  def sell(pair_name, amount, price)
    puts "====> Sell Amount: #{amount} with Price: #{'%.8f' % price} at #{Time.now}"
    result = nil

    begin
      order = JSON.parse(`python -W ignore script/python/sell.py #{pair_name} #{'%.8f' % price} #{amount}`)
      result = {"order_id" => order["orderNumber"]}
      puts "======> SELL FINISH at price: #{'%.8f' % price} - amount: #{amount}"
    rescue Exception => e
      puts "======> SELL ERROR #{e}"
    end
 
    result
  end

  def cancel_order(order_id)
    puts "====> Cancel order at #{Time.now}"

    status = 0
    begin
      result = JSON.parse(`python -W ignore script/python/cancel_order.py #{order_id}`)

      if result['success'] == 1
        status = 1
      end
    rescue Exception => e
      puts "Error #{e}"
      status = -1
    end

    status
  end

  # @return status =1: sold or Bought | =0 : still alive
  def check_order(order_id)
    puts "====> Check order #{order_id} at #{Time.now}"

    status = 0
    begin
      return_value = `python -W ignore script/python/check_trade_order.py #{order_id}`
      if return_value.present?
        result = JSON.parse(return_value)
        if result.present?
          status = 1
        end
      end
    rescue Exception => e
      puts "Error #{e}"
      status = -1
    end
    
    status
  end
  
  def get_balances(currency)
    puts "====> Get balances at #{Time.now}"

    begin
      result = JSON.parse(`python -W ignore script/python/get_balances.py`)
      return result[currency]
    rescue Exception => e
      puts "Error #{e}"
    end

    nil
  end
end
