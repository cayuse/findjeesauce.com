require "rails_helper"

RSpec.describe "Read-only site" do
  %i[post put patch delete].each do |verb|
    it "refuses #{verb.upcase} everywhere" do
      [ "/", "/stores.json", "/stores/1-x", "/nope", "/embed/stores/1-x/shares", "/stores/1-x/shares/2" ].each do |path|
        send(verb, path)
        expect(response).to have_http_status(:method_not_allowed)
        expect(response.headers["allow"]).to eq("GET, HEAD")
      end
    end
  end

  %i[put patch delete].each do |verb|
    it "refuses #{verb.upcase} on the share counter too" do
      send(verb, "/stores/1-x/shares")
      expect(response).to have_http_status(:method_not_allowed)
    end
  end

  it "has no routes but GET, and the one share counter POST" do
    writes = Rails.application.routes.routes.reject { |r| r.verb.blank? || r.verb == "GET" }
    expect(writes.map { |r| [ r.verb, r.path.spec.to_s ] }).to eq([ [ "POST", "/stores/:store_id/shares(.:format)" ] ])
  end
end
