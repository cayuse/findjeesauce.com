# "I found it!" (item 7). POST /stores/:store_id/sightings records one, with an
# optional photo that waits for approval; GET /sightings/:id/photo serves a
# photo once it's approved, and only then. The form posts from our own pages
# and the jeesauce.com frame, so no CSRF token; rate-limited instead.
class SightingsController < ApplicationController
  skip_forgery_protection only: :create
  rate_limit to: 5, within: 1.hour, by: -> { request.remote_ip }, only: :create,
             with: -> { redirect_to finder_store_path(Store.find_by_param!(params[:store_id]), found: "slow", anchor: "found") }

  def create
    store = Store.find_by_param!(params[:store_id])
    sighting = Sighting.new(store_rep_id: store.rep_id, flavor: Flavor.find(params[:flavor])&.name)
    sighting.photo_upload = params[:photo] if Sighting.photos? && params[:photo_ok] == "1"
    found = if sighting.save then sighting.photo_status == "pending" ? "photo" : "1"
    else "bad"
    end
    redirect_to finder_store_path(store, found:, anchor: "found"), status: :see_other
  end

  def photo
    sighting = Sighting.approved.find(params[:id])
    expires_in 1.day, public: true
    send_data sighting.photo, type: "image/jpeg", disposition: "inline"
  end
end
