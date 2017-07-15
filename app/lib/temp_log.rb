module TempLog
  class << self
    def analysis_buy(trade_info, floor_price, previous_price, current_sell_price, changed_sell_percent, changed_with_floor_percent)
      BotTempTradeLog.create({
        currency_pair_id: trade_info.currency_pair_id,
        currency_pair_name: trade_info.currency_pair_name,
        trade_type: 'buy',
        floor_price: floor_price,
        previous_price: previous_price,
        current_price: current_sell_price,
        changed_price_percent: changed_sell_percent,
        changed_with_floor_percent: changed_with_floor_percent
      })
    end

    def analysis_sell(trade_info, ceil_price, previous_price, current_buy_price, changed_buy_percent, changed_with_ceil_percent, profit)
      BotTempTradeLog.create({
        currency_pair_id: trade_info.currency_pair_id,
        currency_pair_name: trade_info.currency_pair_name,
        trade_type: 'sell',
        ceil_price: ceil_price,
        previous_price: previous_price,
        current_price: current_buy_price,
        changed_price_percent: changed_buy_percent,
        changed_with_ceil_percent: changed_with_ceil_percent,
        profit: profit
      })
    end

    def buy(trade_info, amount, price)
      BotTempTradeHistory.create({
        currency_pair_id: trade_info.currency_pair_id,
        currency_pair_name: trade_info.currency_pair_name,
        trade_type: 'buy',
        amount: amount,
        price: price
      })
    end

    def sell(trade_info, amount, price, profit)
      BotTempTradeHistory.create({
        currency_pair_id: trade_info.currency_pair_id,
        currency_pair_name: trade_info.currency_pair_name,
        trade_type: 'sell',
        amount: amount,
        price: price,
        profit: profit
      })
    end
  end
end