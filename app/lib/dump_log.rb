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
  end
end