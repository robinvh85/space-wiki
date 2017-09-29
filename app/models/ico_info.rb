class IcoInfo < ApplicationRecord
  has_many :polo_orders, -> { where ("trading_type <> 'DONE'") }
end
