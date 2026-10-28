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
        @clicks = Click.recent(DAYS).group(:kind, :target).count.sort_by { -_2 }
        @heb_clicks = Click.recent(DAYS).where(target: "H-E-B").where.not(store_rep_id: nil).group(:store_rep_id).count.sort_by { -_2 }.first(25)
        @heb_stores = Store.where(rep_id: @heb_clicks.map(&:first)).index_by(&:rep_id)
        @dtc_spots = Click.recent(DAYS).where(kind: "dtc").group(:spot).count.sort_by { -_2 }
        @share_channels = Share.group(:channel).count
        @open_channels = ShareOpen.group(:channel).count
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
