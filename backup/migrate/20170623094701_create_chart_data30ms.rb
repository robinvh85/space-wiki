class CreateChartData30ms < ActiveRecord::Migration[5.0]
  def change
    create_table :chart_data30ms do |t|
      t.integer :currency_pair_id
      t.timestamp :date_time
      t.bigint    :time_at
      t.decimal :high, precision: 16, scale: 8
      t.decimal :low, precision: 16, scale: 8
      t.decimal :open, precision: 16, scale: 8
      t.decimal :close, precision: 16, scale: 8
      t.decimal :volume, precision: 16, scale: 8
      t.decimal :quote_volume, precision: 16, scale: 8
      t.decimal :weighted_average, precision: 16, scale: 8
      t.decimal :min_value, precision: 16, scale: 8

      t.index [:currency_pair_id, :time_at], name: 'idx_pair_time_at', unique: true      
    end
  end
end
