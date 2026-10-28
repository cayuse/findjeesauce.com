# Per-request memo (reset between requests by Rails).
class Current < ActiveSupport::CurrentAttributes
  attribute :broken_urls
end
