# A click out to somewhere that sells JeeSauce. See the migration. The page
# says where it went by host; this maps the host to a name we keep.
class Click < ApplicationRecord
  TARGETS = {
    "heb.com" => [ "chain", "H-E-B" ], "albertsons.com" => [ "chain", "Albertsons" ],
    "safeway.com" => [ "chain", "Safeway" ], "jewelosco.com" => [ "chain", "Jewel-Osco" ],
    "betterhealthmarket.com" => [ "chain", "Better Health Market" ],
    "instacart.com" => [ "delivery", "Instacart" ], "doordash.com" => [ "delivery", "DoorDash" ],
    "ubereats.com" => [ "delivery", "Uber Eats" ],
    "jeesauce.com" => [ "dtc", "jeesauce.com" ], "google.com" => [ "directions", "Directions" ]
  }.freeze

  scope :recent, ->(days = 90) { where(created_at: days.days.ago..) }

  # From the page's report of a click: the link's host (www. dropped), and
  # what it knew. Nil for a host we don't count.
  def self.from(host:, store_rep_id:, flavor:, spot:)
    kind, target = TARGETS[host.to_s.downcase.delete_prefix("www.")]
    return unless kind

    new(kind:, target:, store_rep_id: Integer(store_rep_id, exception: false),
        flavor: Flavor.find(flavor)&.name, spot: spot.to_s[/\A[a-z-]{1,40}\z/])
  end
end
