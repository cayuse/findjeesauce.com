# A store someone sent a friend. See the migration for what's kept (and not).
class Share < ApplicationRecord
  CHANNELS = %w[copy text email whatsapp native x facebook caption picture video].freeze

  validates :channel, inclusion: { in: CHANNELS }
  validates :store_rep_id, presence: true

  def self.for_store(store) = where(store_rep_id: store.rep_id)
end
