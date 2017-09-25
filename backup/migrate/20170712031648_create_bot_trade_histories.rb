class CreateBotTradeHistories < ActiveRecord::Migration[5.0]
  def change
    create_table :bot_trade_histories do |t|
      t.integer   :currency_pair_id
      t.string    :currency_pair_name
      t.string    :trade_type
      t.decimal   :amount, precision: 16, scale: 8
      t.decimal   :price, precision: 16, scale: 8
      t.float     :profit

      t.timestamps
    end
  end
end
