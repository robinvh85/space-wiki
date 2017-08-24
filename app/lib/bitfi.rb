class Bitfi
  def initialize(config)
    Bitfinex::Client.configure do |conf|
      conf.api_key = config[:key]
      conf.secret = config[:secret]
    end

    @client = @client = Bitfinex::Client.new
  end

  def get_current_trading_price(pair_name, limit_amount)

    begin
      data = @client.orderbook(pair_name)
      
      buy_price = 0

      if data['bids'].nil?
        puts "#{pair_name} - CAN NOT GET PRICE !!!!!"
        return nil 
      end

      data['bids'].each do |bid|
        if bid["amount"].to_f > limit_amount
          buy_price = bid["price"].to_f
          break
        end
      end

      sell_price = 0
      data['asks'].each do |ask|
        if ask["amount"].to_f > limit_amount
          sell_price = ask["price"].to_f
          break
        end
      end

      {
        buy_price: buy_price,
        sell_price: sell_price
      }
    rescue Exception => e
      puts "Error - #{pair_name} - #{e}"
      nil
    end
  end

  def buy(pair_name, amount, price)
    puts "====> Buy with Amount: #{amount} at Price: #{'%.8f' % price} at #{Time.now}"
    result = nil

    begin
      result = @client.new_order(pair_name, amount, "exchange limit", "buy", price)
      puts "======> BUY FINISH at price: #{'%.8f' % price} - amount: #{amount}"
    rescue Exception => e
      puts "======> BUY ERROR #{e}"
    end

    result
  end

  def sell(pair_name, amount, price)
    puts "====> Sell Amount: #{amount} with Price: #{'%.8f' % price} at #{Time.now}"
    result = nil

    begin
      result = @client.new_order(pair_name, amount, "exchange limit", "sell", price)
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
      result = @client.cancel_orders(order_id)
      status = 1
    rescue Exception => e
      puts "Error #{e}"
    end

    status
  end

  # @return status =1: sold or Bought | =0 : still alive
  def check_order(order_id)
    puts "====> Check order #{order_id} at #{Time.now}"

    begin
      result = @client.order_status(order_id)
      status = 0
      if result["is_live"] == false and result["original_amount"] == result["executed_amount"]
        status = 1
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
      result = @client.balances
      result.each do |item|
        if item["currency"] == currency
          return item["available"].to_f
        end
      end
    rescue Exception => e
      puts "Error #{e}"
    end

    nil
  end
end