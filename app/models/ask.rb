# A shopper asked a store to carry JeeSauce. See the migration.
class Ask < ApplicationRecord
  include CoarsePlace

  validates :chain, inclusion: { in: ->(_) { Retailer::REQUESTS.keys + [ "other" ] } }

  scope :recent, ->(days = 90) { where(created_at: days.days.ago..) }
end
