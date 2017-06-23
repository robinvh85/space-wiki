class CurrencyPair < ApplicationRecord
  has_many :chart_data, :class_name => "ChartData"
end
