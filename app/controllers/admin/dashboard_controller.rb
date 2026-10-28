# /admin: where shoppers look and come up empty (Search), what they asked
# stores for (Ask), photos to approve, and the nightly link check.
class Admin::DashboardController < Admin::BaseController
  DAYS = 90

  def show
    @demand = Search.demand(days: DAYS)
    respond_to do |format|
      format.html do
        @search_count = Search.recent(DAYS).count
        @empty_count = Search.recent(DAYS).empty.count
        @flavor_counts = Search.recent(DAYS).where.not(flavor: nil).group(:flavor).count.sort_by { -_2 }
        @asks = Ask.recent(DAYS).group(:chain).count.sort_by { -_2 }
        @ask_places = Ask.recent(DAYS).where.not(zip: nil).group(:zip).count.sort_by { -_2 }.first(20)
        @pending_photos = Sighting.pending.count
        @sightings = Sighting.fresh.count
        @shares = Share.count
        @links = LinkCheck.order(:result, :url)
      end
      format.csv { send_data demand_csv, filename: "findjeesauce-demand-#{Date.current}.csv" }
    end
  end

  private

  # Numbers, ZIP digits and state codes only, so no quoting needed (and no
  # csv gem, which left Ruby's standard library in 3.4).
  def demand_csv
    rows = @demand.map { |d| d.values_at(:lat, :lng, :zip, :state, :total, :empty, :nearest_miles).join(",") }
    [ "lat,lng,zip,state,searches,empty_searches,nearest_store_miles", *rows ].join("\n") + "\n"
  end
end
