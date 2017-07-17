module DumpLog
  class << self
    def analysis_buy(trade_info, floor_price, previous_price, current_sell_price, changed_sell_percent, changed_with_floor_percent)
      BotDumpTradeLog.create({
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

    def analysis_up(trade_info, floor_price, previous_price, current_up_price, changed_up_percent, changed_with_floor_percent, price_24h_percent)
      BotDumpTradeLog.create({
        currency_pair_id: trade_info.currency_pair_id,
        currency_pair_name: trade_info.currency_pair_name,
        trade_type: 'up',
        floor_price: floor_price,
        previous_price: previous_price,
        current_price: current_up_price,
        changed_price_percent: changed_up_percent,
        changed_with_floor_percent: changed_with_floor_percent,
        price_24h_percent: price_24h_percent
      })
    end

    def analysis_down(trade_info, ceil_price, previous_price, current_down_price, changed_down_percent, changed_with_ceil_percent, price_24h_percent)
      BotDumpTradeLog.create({
        currency_pair_id: trade_info.currency_pair_id,
        currency_pair_name: trade_info.currency_pair_name,
        trade_type: 'up',
        floor_price: ceil_price,
        previous_price: previous_price,
        current_price: current_down_price,
        changed_price_percent: changed_down_percent,
        changed_with_floor_percent: changed_with_ceil_percent,
        price_24h_percent: price_24h_percent
      })
    end
  end
end