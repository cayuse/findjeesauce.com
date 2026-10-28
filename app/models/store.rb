# A store that carries JeeSauce, as rep's feed last said. Read-only here:
# StoreFeed.sync! is the only writer.
class Store < ApplicationRecord
  EARTH_RADIUS_MILES = 3958.8
  DEFAULT_RADIUS_MILES = 50
  NEAR_LIMIT = 25

  US_STATES = {
    "alabama" => "AL", "alaska" => "AK", "arizona" => "AZ", "arkansas" => "AR", "california" => "CA",
    "colorado" => "CO", "connecticut" => "CT", "delaware" => "DE", "florida" => "FL", "georgia" => "GA",
    "hawaii" => "HI", "idaho" => "ID", "illinois" => "IL", "indiana" => "IN", "iowa" => "IA",
    "kansas" => "KS", "kentucky" => "KY", "louisiana" => "LA", "maine" => "ME", "maryland" => "MD",
    "massachusetts" => "MA", "michigan" => "MI", "minnesota" => "MN", "mississippi" => "MS",
    "missouri" => "MO", "montana" => "MT", "nebraska" => "NE", "nevada" => "NV", "new hampshire" => "NH",
    "new jersey" => "NJ", "new mexico" => "NM", "new york" => "NY", "north carolina" => "NC",
    "north dakota" => "ND", "ohio" => "OH", "oklahoma" => "OK", "oregon" => "OR", "pennsylvania" => "PA",
    "rhode island" => "RI", "south carolina" => "SC", "south dakota" => "SD", "tennessee" => "TN",
    "texas" => "TX", "utah" => "UT", "vermont" => "VT", "virginia" => "VA", "washington" => "WA",
    "west virginia" => "WV", "wisconsin" => "WI", "wyoming" => "WY", "district of columbia" => "DC"
  }.freeze

  scope :located, -> { where.not(lat: nil).where.not(lng: nil) }
  scope :carrying, ->(flavor) { where("? = ANY(stores.flavors)", flavor.name) }

  # Nearest stores to a point, each with a `distance` in miles.
  def self.near(lat, lng, within: DEFAULT_RADIUS_MILES, limit: NEAR_LIMIT)
    distance = <<~SQL.squish
      #{EARTH_RADIUS_MILES} * 2 * asin(sqrt(
        power(sin(radians((stores.lat - #{lat.to_f}) / 2)), 2) +
        cos(radians(#{lat.to_f})) * cos(radians(stores.lat)) *
        power(sin(radians((stores.lng - #{lng.to_f}) / 2)), 2)))
    SQL
    located.select("stores.*, #{distance} AS distance")
           .where("#{distance} <= ?", within).order(Arel.sql("distance")).limit(limit)
  end

  # Without a map key there is no geocoder, so a typed search is matched
  # against the stores themselves: an exact ZIP, its first three digits, or a
  # city / state name.
  def self.text_search(query)
    q = query.to_s.strip
    return none if q.blank?

    if (zip = q[/\A\d{5}/])
      exact = where("zip LIKE ?", "#{zip}%")
      return exact if exact.exists?

      return where("zip LIKE ?", "#{zip[0, 3]}%")
    end
    city, state = q.split(",", 2).map(&:strip)
    code = normalize_state(state.presence || city)
    return where(state: code) if state.blank? && code&.length == 2 && US_STATES.value?(code)

    scope = where("lower(city) = ?", city.downcase)
    scope = scope.where(state: normalize_state(state)) if state.present?
    scope
  end

  def self.normalize_state(value)
    v = value.to_s.strip
    return nil if v.empty?

    US_STATES[v.downcase] || v.upcase
  end

  # "78703-0" → "78703"; keeps a real ZIP+4.
  def self.normalize_zip(value)
    v = value.to_s.strip
    v[/\A\d{5}-\d{4}\z/] || v[/\A\d{5}/] || v.presence
  end

  def to_param = [ rep_id, name, city, state ].compact.join(" ").parameterize

  def self.find_by_param!(param) = find_by!(rep_id: param.to_s[/\A\d+/])

  # Three states, never two: a store with no flavor list is unknown (rep
  # doesn't know what's on its shelf), not a store that carries nothing.
  def flavor_state(flavor)
    return :unknown if flavors.empty?

    flavors.include?(flavor.name) ? :carries : :doesnt
  end

  def sorted_flavors = Flavor.sort_names(flavors)

  # [flavor name, URL] for each flavor this store carries that its chain sells
  # on its own site ("Buy at H-E-B").
  def chain_links = sorted_flavors.filter_map { |name| (url = Flavor.chain_link(shop_chain, name)) && [ name, url ] }

  # Which chain's shop links apply: see Flavor.shop_chain.
  def shop_chain = Flavor.shop_chain(chain, name)

  def located? = lat.present? && lng.present?
  def address_line = [ street, street2 ].compact_blank.join(", ")
  def place_line = [ city, [ state, zip ].compact_blank.join(" ") ].compact_blank.join(", ")
  def directions_url = "https://www.google.com/maps/dir/?api=1&destination=#{CGI.escape([ name, address_line, place_line ].compact_blank.join(', '))}"
end
