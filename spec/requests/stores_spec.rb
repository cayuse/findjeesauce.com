require "rails_helper"

RSpec.describe "Store pages" do
  let!(:store) { Store.create!(rep_id: 7, name: "Vista Market", city: "Vista", state: "CA", zip: "92081", lat: 33.2, lng: -117.24, flavors: [ "Original" ]) }

  it "shows the search page" do
    get root_path
    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Find JeeSauce near you")
  end

  it "searches by coordinates" do
    get root_path, params: { lat: 33.21, lng: -117.25 }
    expect(response.body).to include("Vista Market")
  end

  it "searches by ZIP without a maps key" do
    get root_path, params: { q: "92081" }
    expect(response.body).to include("Vista Market")
  end

  it "says so when nothing matches" do
    get root_path, params: { q: "10001" }
    expect(response.body).to include("No stores found")
  end

  it "shows a store and redirects old slugs to the current one" do
    get store_path(store)
    expect(response.body).to include("Original")
    get "/stores/7-old-name"
    expect(response).to redirect_to(store_path(store))
    expect(response).to have_http_status(:moved_permanently)
  end

  it "serves the public JSON copy with CORS open" do
    get "/stores.json"
    expect(response.headers["Access-Control-Allow-Origin"]).to eq("*")
    expect(response.parsed_body["data"].first).to include("name" => "Vista Market", "url" => "http://www.example.com/stores/7-vista-market-vista-ca")
  end

  it "keeps staging out of search engines" do
    ENV["NOINDEX"] = "1"
    get "/robots.txt"
    expect(response.body).to include("Disallow: /")
    expect(response.headers["X-Robots-Tag"]).to eq("noindex, nofollow")
  ensure
    ENV.delete("NOINDEX")
  end
end

RSpec.describe CanonicalHost do
  it "sends www to the bare domain, keeping the path" do
    app = ->(_) { [ 200, {}, [ "ok" ] ] }
    ENV["CANONICAL_HOST"] = "findjeesauce.com"
    status, headers, = CanonicalHost.new(app).call(Rack::MockRequest.env_for("https://www.findjeesauce.com/stores/7?x=1"))
    expect(status).to eq(301)
    expect(headers["location"]).to eq("https://findjeesauce.com/stores/7?x=1")
  ensure
    ENV.delete("CANONICAL_HOST")
  end
end
