# A finder search, for the demand map. See the migration for what's kept.
class Search < ApplicationRecord
  include CoarsePlace

  BOT = /bot|crawl|spider|slurp|preview|fetch|monitor|curl|wget|python|headless/i

  scope :recent, ->(days = 90) { where(created_at: days.days.ago..) }
  scope :empty, -> { where(nearby_count: 0) }

  # Called once per searched results page. Never raises: a missed row must not
  # cost the shopper their results.
  def self.log(user_agent:, zip:, lat:, lng:, state:, flavor:, nearby_count:, carrier_count:, nearest_miles:)
    return if user_agent.blank? || user_agent.match?(BOT)

    create!(**coarse(zip:, lat:, lng:), state:, flavor: flavor&.name, nearby_count:, carrier_count:,
            nearest_miles: nearest_miles&.round)
  rescue StandardError => e
    Rails.logger.warn("Search.log failed: #{e.class}: #{e.message}")
  end

  # Searches grouped by place, the emptiest and busiest first. One row per
  # 0.1° square (or per ZIP for typed-ZIP searches without a point).
  def self.demand(days: 90)
    recent(days).group(:lat, :lng).order(Arel.sql("count(*) FILTER (WHERE nearby_count = 0) DESC, count(*) DESC"))
                .pluck(:lat, :lng, Arel.sql("count(*)"), Arel.sql("count(*) FILTER (WHERE nearby_count = 0)"),
                       Arel.sql("max(zip)"), Arel.sql("max(state)"), Arel.sql("min(nearest_miles)"))
                .map { |lat, lng, total, empty, zip, state, nearest| { lat:, lng:, total:, empty:, zip:, state:, nearest_miles: nearest } }
  end
end
