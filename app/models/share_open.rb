# A friend opened a shared link ("love landed"). See the migration.
class ShareOpen < ApplicationRecord
  CHANNELS = %w[text email whatsapp link sheet x facebook].freeze

  def self.log(store:, via:, user_agent:)
    return if user_agent.blank? || user_agent.match?(Search::BOT)

    create!(store_rep_id: store.rep_id, channel: via.presence_in(CHANNELS) || "unknown")
  rescue StandardError => e
    Rails.logger.warn("ShareOpen.log failed: #{e.class}: #{e.message}")
  end
end
