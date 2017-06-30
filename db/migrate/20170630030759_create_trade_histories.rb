class CreateTradeHistories < ActiveRecord::Migration[5.0]
  def change
    create_table :trade_histories do |t|
      t.string  :category
      t.string :trade_id
      t.string :order_number
      t.string :trade_type
      t.decimal :fee, precision: 16, scale: 8
      t.decimal :amount, precision: 20, scale: 8
      t.decimal :rate, precision: 16, scale: 8
      t.decimal :total, precision: 16, scale: 8
      t.timestamp :date_time
      t.integer :is_sold, default: 0
      t.integer :currency_pair_id
      t.string  :currency_pair_name
    end
  end
end
