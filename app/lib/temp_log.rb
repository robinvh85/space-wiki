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

    def buy(bot_trade_history, amount, price)
      bot_trade_history.buy_price = price
      bot_trade_history.amount = amount
      bot_trade_history.save!
    end

    def sell(bot_trade_history, amount, price, profit)
      bot_trade_history.sell_price = price
      bot_trade_history.profit = profit
      bot_trade_history.save!
    end
  end
end