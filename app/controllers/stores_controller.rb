class StoresController < ApplicationController
  WIDER_RADIUS_MILES = 250
  # How far "the nearest store with this flavor" may be before we stop
  # offering the drive and only offer the order online.
  NEAREST_CARRIER_MILES = 150
  STATE_ORDER = { carries: 0, unknown: 1, doesnt: 2 }.freeze

  def index
    @query = params[:q].to_s.strip.first(100)
    @lat = coordinate(params[:lat], 90)
    @lng = coordinate(params[:lng], 180)

    if @lat && @lng
      @stores = Store.near(@lat, @lng).to_a
      if @stores.empty?
        @stores = Store.near(@lat, @lng, within: WIDER_RADIUS_MILES, limit: 10).to_a
        @widened = @stores.any?
      end
      @searched = true
    elsif @query.present?
      @stores = Store.text_search(@query).order(:state, :city, :name).limit(100).to_a
      @searched = true
    else
      @stores = []
    end
    @store_count = Store.count
    @state_count = Store.distinct.count(:state)
    pick_flavor
    return unless @searched

    @nothing_near = @stores.empty? || @widened
    @spotted = Sighting.latest_for(@stores)
    log_search
  end

  def show
    @flavor = Flavor.find(params[:flavor])
    @store = Store.find_by_param!(params[:id])
    @shared = params[:shared] == "1"
    return redirect_to(finder_store_path(@store, flavor: @flavor&.slug, shared: (1 if @shared)), status: :moved_permanently) if params[:id] != @store.to_param

    @nearby = @store.located? ? Store.near(@store.lat, @store.lng, within: 25, limit: 7).where.not(id: @store.id).to_a : []
    @spotted = Sighting.latest_for([ @store, *@nearby ])
    @photos = Sighting.for_store(@store).approved.select(:id, :flavor, :created_at).limit(6)
    @found = params[:found].presence_in(%w[1 photo])
  end

  private

  # ?flavor=dilly-dilly: carriers first (then unknowns, then the rest, each
  # still nearest-first), a count for the notice, and, when nothing in the
  # results has it, the nearest store that does.
  def pick_flavor
    @flavor = Flavor.find(params[:flavor])
    return unless @flavor

    @flavor_store_count = Store.carrying(@flavor).count
    return unless @searched

    @stores = @stores.each_with_index.sort_by { |s, i| [ STATE_ORDER[s.flavor_state(@flavor)], i ] }.map(&:first)
    @carrier_count = @stores.count { |s| s.flavor_state(@flavor) == :carries }
    if @carrier_count.zero? && @lat && @flavor_store_count.positive?
      @nearest_carrier = Store.near(@lat, @lng, within: NEAREST_CARRIER_MILES, limit: 1).carrying(@flavor).first
    end
  end

  # One row for the demand map (Search). Coarse place only.
  def log_search
    nearby = @nothing_near ? 0 : @stores.size
    Search.log(user_agent: request.user_agent, zip: @query, lat: @lat, lng: @lng,
               state: (@stores.first&.state unless @nothing_near), flavor: @flavor, nearby_count: nearby,
               carrier_count: (@carrier_count if @flavor), nearest_miles: @stores.first.try(:distance))
  end

  def coordinate(value, max)
    f = Float(value, exception: false)
    f if f && f.abs <= max
  end
end
