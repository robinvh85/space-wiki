class IcoBot < ApplicationRecord
  belongs_to :ico_order, optional: true
  belongs_to :ico_info
  belongs_to :ico_account
end
