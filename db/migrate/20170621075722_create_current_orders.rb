class CreateCurrentOrders < ActiveRecord::Migration[5.0]
  def change
    create_table :current_orders do |t|
      t.string 		:currency_pair
      t.string    :method
      t.float     :price
      t.float     :amount
      t.float     :total_price
      t.float     :accumulate_price
    end
  end
end
