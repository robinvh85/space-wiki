class IcoBot < ApplicationRecord
  belongs_to :ico_order, optional: true
  belongs_to :ico_info
  belongs_to :ico_account
  belongs_to :ico_invest
end
