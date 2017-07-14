module TempLog
  class << self
    def analysis_buy(pair, floor_price, previous_price, current_sell_price, changed_sell_percent, changed_with_floor_percent)
      BotTempTradeLog.create({
        currency_pair_id: pair.id,
        currency_pair_name: pair.name,
        trade_type: 'buy',
        floor_price: floor_price,
        previous_price: previous_price,
        current_price: current_sell_price,
        changed_price_percent: changed_sell_percent,
        changed_with_floor_percent: changed_with_floor_percent
      })
    end

    def analysis_sell(pair, ceil_price, previous_price, current_buy_price, changed_buy_percent, changed_with_ceil_percent, profit)
      BotTempTradeLog.create({
        currency_pair_id: pair.id,
        currency_pair_name: pair.name,
        trade_type: 'sell',
        ceil_price: ceil_price,
        previous_price: previous_price,
        current_price: current_buy_price,
        changed_price_percent: changed_buy_percent,
        changed_with_ceil_percent: changed_with_ceil_percent,
        profit: profit
      })
    end

    def buy(pair, amount, price)
      BotTempTradeHistory.create({
        currency_pair_id: pair.id,
        currency_pair_name: pair.name,
        trade_type: 'buy',
        amount: amount,
        price: price
      })
    end

    def sell(pair, amount, price, profit)
      BotTempTradeHistory.create({
        currency_pair_id: pair.id,
        currency_pair_name: pair.name,
        trade_type: 'sell',
        amount: amount,
        price: price,
        profit: profit
      })
    end
  end
end