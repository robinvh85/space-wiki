class CreateOpenOrders < ActiveRecord::Migration[5.0]
  def change
    create_table :open_orders do |t|
      t.string  :order_number
      t.decimal :margin, precision: 16, scale: 8
      t.decimal :amount, precision: 16, scale: 8
      t.decimal :price, precision: 16, scale: 8
      t.decimal :total, precision: 16, scale: 8
      t.decimal :starting_amount, precision: 16, scale: 8
      t.timestamp :date_time
    end
  end
end
