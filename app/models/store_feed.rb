# Copies rep's store feed into `stores`. Rules:
# - Only a COMPLETE fetch replaces the table, in one transaction. Any error
#   leaves the last good copy in place: a broken rep link makes the finder
#   stale, never empty.
# - A feed that would wipe out most of the list is refused, not applied
#   (a rep bug or a bad filter shouldn't empty the public site).
# - Every attempt is a SyncRun row.
class StoreFeed
  # Refuse a feed that drops more than this share of the current stores.
  MAX_DROP = 0.5
  EXPIRY_WARNING = 60.days

  def self.sync!(client: Rep::Client.default) = new(client).sync!

  def initialize(client)
    @client = client
  end

  def sync!
    run = SyncRun.create!(status: "failed", started_at: Time.current)
    # Ask "anything new?" only when we hold a copy to keep.
    feed = @client.stores(etag: (SyncRun.last_good&.etag if Store.exists?))
    warn_if_expiring(feed.token_expires_at)
    run.token_expires_at = feed.token_expires_at

    if feed.not_modified
      run.update!(status: "not_modified", etag: feed.etag, stores_count: Store.count, finished_at: Time.current)
      return run
    end

    current = Store.count
    if current.positive? && feed.rows.size < current * (1 - MAX_DROP)
      run.update!(status: "refused", stores_count: feed.rows.size, finished_at: Time.current,
                  error: "Feed has #{feed.rows.size} stores; we have #{current}. Refused a drop over #{(MAX_DROP * 100).round}%.")
      Rails.logger.error("[store_feed] #{run.error}")
      return run
    end

    apply(feed.rows)
    run.update!(status: "ok", stores_count: feed.rows.size, etag: feed.etag, feed_as_of: feed.as_of, finished_at: Time.current)
    run
  rescue Rep::Client::Error, JSON::ParserError, KeyError => e
    run&.update!(status: "failed", error: e.message, finished_at: Time.current)
    Rails.logger.error("[store_feed] sync failed: #{e.message}")
    run
  end

  private

  def apply(rows)
    records = rows.map { |r| attributes(r) }
    Store.transaction do
      Store.upsert_all(records, unique_by: :rep_id) if records.any? # sets created_at / updated_at itself
      Store.where.not(rep_id: records.map { |r| r[:rep_id] }).delete_all
    end
  end

  def attributes(r)
    {
      rep_id: Integer(r.fetch("id")),
      name: r.fetch("name").to_s.strip,
      chain: r["chain"].presence,
      street: r["street"].presence,
      street2: r["street2"].presence,
      city: r["city"].to_s.strip.presence,
      state: Store.normalize_state(r["state"]),
      zip: Store.normalize_zip(r["zip"]),
      lat: r["lat"],
      lng: r["lng"],
      flavors: Array(r["flavors"]).map(&:to_s),
      rep_updated_at: r["updated_at"].present? ? Time.iso8601(r["updated_at"]) : nil
    }
  end

  def warn_if_expiring(expires_at)
    return unless expires_at && expires_at < EXPIRY_WARNING.from_now

    Rails.logger.warn("[store_feed] rep token expires #{expires_at.iso8601}: rotate it (rep docs/API_CLIENTS_AND_TOKENS.md)")
  end
end
