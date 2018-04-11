class CreateCurrentOrders < ActiveRecord::Migration[5.0]
  def change
    create_table :current_orders do |t|
      t.string 		:currency_pair
      t.string    :method
      t.string     :price
      t.string     :amount
      t.string     :total_price
      t.string     :accumulate_price

      t.timestamps
    end
  end
end
