class CreateBotTradeLogs < ActiveRecord::Migration[5.0]
  def change
    create_table :bot_trade_logs do |t|
      t.integer   :currency_pair_id
      t.string    :currency_pair_name
      t.string    :trade_type
      t.decimal   :ceil_price, precision: 16, scale: 8
      t.decimal   :floor_price, precision: 16, scale: 8
      t.decimal   :previous_price, precision: 16, scale: 8
      t.decimal   :current_price, precision: 16, scale: 8
      t.float     :profit

      t.timestamps
    end
  end
end
