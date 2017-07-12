class CreateCurrencyPairs < ActiveRecord::Migration[5.0]
  def change
    create_table :currency_pairs do |t|
      t.string    :name
      t.string    :long_name
      t.int       :is_init
      t.int       :is_tracking
      t.sort      :sort
      t.string    :base_unit
      t.decimal   :percent_min_24h, precision: 4, scale: 2
    end
  end
end
