class BotBtc < ApplicationRecord
  belongs_to :order_btc, optional: true
end
