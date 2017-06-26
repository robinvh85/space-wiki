class CreateCurrencyPairs < ActiveRecord::Migration[5.0]
  def change
    create_table :currency_pairs do |t|
      t.string    :name
      t.int       :is_init
      t.sort      :sort
      t.string    :base_unit
    end
  end
end
