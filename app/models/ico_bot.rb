class IcoBot < ApplicationRecord
  belongs_to :ico_order, optional: true
end
