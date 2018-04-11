class CreateBotTradeInfos < ActiveRecord::Migration[5.0]
  def change
    create_table :bot_trade_infos do |t|
      t.integer  :currency_pair_id
      t.string   :currency_pair_name
      t.decimal  :buy_amount, precision: 16, scale: 8
      t.float    :limit_invert_when_buy
      t.float    :limit_invert_when_sell
      t.float    :limit_good_profit
      t.float    :limit_losses_profit
      t.integer  :interval_time
      t.integer  :limit_verify_times
      t.integer  :delay_time_after_sold
      t.integer  :status
      
      t.timestamps
    end
  end
end
