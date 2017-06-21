class CreateCurrencyPairs < ActiveRecord::Migration[5.0]
  def change
    create_table :currency_pairs do |t|
      t.string    :name
    end
  end
end
