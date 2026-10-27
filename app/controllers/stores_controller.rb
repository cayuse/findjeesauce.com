class StoresController < ApplicationController
  WIDER_RADIUS_MILES = 250

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
  end

  def show
    @store = Store.find_by_param!(params[:id])
    return redirect_to(store_path(@store), status: :moved_permanently) if params[:id] != @store.to_param

    @nearby = @store.located? ? Store.near(@store.lat, @store.lng, within: 25, limit: 7).where.not(id: @store.id).to_a : []
  end

  private

  def coordinate(value, max)
    f = Float(value, exception: false)
    f if f && f.abs <= max
  end
end
