module Log
  class << self
    def analysis_buy(bot_trade_history, floor_price, previous_price, current_sell_price, changed_sell_percent, changed_with_floor_percent)
      BotTradeLog.create({
        bot_trade_history_id: bot_trade_history.id,
        currency_pair_id: bot_trade_history.currency_pair_id,
        currency_pair_name: bot_trade_history.currency_pair_name,
        trade_type: 'buy',
        floor_price: floor_price,
        previous_price: previous_price,
        current_price: current_sell_price,
        changed_price_percent: changed_sell_percent,
        changed_with_floor_percent: changed_with_floor_percent
      })
    end

    def analysis_sell(bot_trade_history, ceil_price, previous_price, current_buy_price, changed_buy_percent, changed_with_ceil_percent, profit)
      BotTradeLog.create({
        bot_trade_history_id: bot_trade_history.id,
        currency_pair_id: bot_trade_history.currency_pair_id,
        currency_pair_name: bot_trade_history.currency_pair_name,
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

    def difference_buy_sell(trade_info, buy_price, sell_price, difference_percent)
      DifferenceBuySell.create({
        currency_pair_id: trade_info.currency_pair_id,
        currency_pair_name: trade_info.currency_pair_name,
        buy_price: buy_price,
        sell_price: sell_price,
        difference_percent: difference_percent
      })
    end
  end
end