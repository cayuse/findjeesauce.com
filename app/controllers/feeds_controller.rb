# GET /stores.json — every store, for jeesauce.com to embed. Public on
# purpose: it is the same list the pages show, so anyone may read it
# (Access-Control-Allow-Origin: *). Rep is never exposed: this is our copy.
class FeedsController < ApplicationController
  def stores
    last = SyncRun.last_good
    expires_in 10.minutes, public: true
    response.set_header("Access-Control-Allow-Origin", "*")
    return unless stale?(etag: [ "stores-v1", last&.id, Store.maximum(:updated_at) ], public: true)

    render json: {
      data: Store.located.order(:id).map { |s| row(s) },
      meta: { as_of: last&.finished_at&.utc&.iso8601, count: Store.located.count }
    }
  end

  private

  def row(s)
    { id: s.rep_id, name: s.name, chain: s.chain, street: s.street, street2: s.street2, city: s.city,
      state: s.state, zip: s.zip, lat: s.lat.to_f, lng: s.lng.to_f, flavors: s.flavors, url: store_url(s) }
  end
end
