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

RSpec.describe "Embed pages" do
  let!(:store) { Store.create!(rep_id: 7, name: "Vista Market", city: "Vista", state: "CA", zip: "92081", lat: 33.2, lng: -117.24) }

  it "lets only jeesauce.com and Shopify previews frame the finder" do
    get "/embed"
    expect(response).to have_http_status(:ok)
    expect(response.headers["X-Frame-Options"]).to be_nil
    expect(response.headers["Content-Security-Policy"]).to include("frame-ancestors 'self' https://jeesauce.com")
    expect(response.headers["Content-Security-Policy"]).to include("https://*.shopifypreview.com")
  end

  it "keeps links inside the frame" do
    get "/embed", params: { q: "92081" }
    expect(response.body).to include("/embed/stores/7-vista-market-vista-ca")
    expect(response.body).not_to include("Order online")
  end

  it "refuses framing everywhere else" do
    get "/"
    expect(response.headers["X-Frame-Options"]).to eq("SAMEORIGIN")
  end
end

RSpec.describe "Finding a flavor" do
  let(:near) { { lat: 30.45, lng: -97.83 } }
  let!(:heb) do
    Store.create!(rep_id: 17, name: "Anderson Mill H-E-B", chain: "H-E-B", city: "Austin", state: "TX", zip: "78726",
                  lat: 30.452, lng: -97.827, flavors: [ "Sun-Dried Tomato Basil", "Original" ])
  end
  let!(:mystery) { Store.create!(rep_id: 18, name: "Mystery Market", city: "Austin", state: "TX", zip: "78726", lat: 30.451, lng: -97.826, flavors: []) }
  let!(:far_chipotle) { Store.create!(rep_id: 19, name: "Waco Chipotle Co-op", city: "Waco", state: "TX", zip: "76701", lat: 31.55, lng: -97.15, flavors: [ "Chipotle" ]) }

  it "shows every flavor's lid as a link" do
    get root_path
    Flavor.all.each { |f| expect(response.body).to include("flavor=#{f.slug}") }
    expect(response.body).to include("lids/dilly-dilly")
  end

  it "lists carriers first and never counts a store with no flavor list" do
    get root_path, params: near.merge(flavor: "original")
    expect(response.body).to include("1 store near you carries Original")
    expect(response.body.index("Anderson Mill")).to be < response.body.index("Mystery Market")
    expect(response.body).to include("1 store here doesn&#39;t list its flavors: call ahead")
  end

  it "points to the nearest store that has it, and the order-online link, when none nearby do" do
    get root_path, params: near.merge(flavor: "chipotle")
    expect(response.body).to include("Chipotle isn't on a shelf near you yet")
    expect(response.body).to include("Waco Chipotle Co-op")
    expect(response.body).to include("https://jeesauce.com/products/8oz-chipotle-jeesauce")
  end

  it "says online only when no store has the flavor" do
    get root_path, params: { flavor: "dilly-dilly" }
    expect(response.body).to include("Online only, for now.")
  end

  it "ignores a flavor it doesn't know" do
    get root_path, params: { flavor: "nope" }
    expect(response).to have_http_status(:ok)
    expect(response.body).not_to include("on the shelf at")
  end

  it "links H-E-B stores to the flavor's page on heb.com, and only for checked links" do
    get store_path(heb)
    expect(response.body).to include(Flavor.chain_link("H-E-B", "Original"))
    expect(response.body).to include(Flavor.chain_link("H-E-B", "Sun-Dried Tomato Basil"))
    expect(response.body.scan("Buy at H-E-B").size).to eq(2) # the two flavors this store lists
  end

  it "puts the chosen flavor's H-E-B link on the store card" do
    get root_path, params: near.merge(flavor: "original")
    expect(response.body).to include("Buy Original at H-E-B")
    expect(response.body).to include("https://www.heb.com/product-detail/jeesauce-original-almond-based-dip-9-oz/16045543")
  end

  it "tells a shopper when this store doesn't list the flavor they picked" do
    get store_path(heb, flavor: "chipotle")
    expect(response.body).to include("This store doesn't list Chipotle")
  end
end

RSpec.describe "Available at" do
  it "lists the big chains, each linked to its own site" do
    get root_path
    expect(response.body).to include("Available at", "and many more!")
    Flavor::RETAILERS.each { |shop| expect(response.body).to include(shop[:name], shop[:url]) }
  end

  it "links a Better Health Market store, which comes through with no chain, to its shop" do
    store = Store.create!(rep_id: 31, name: "Better Health Market Novi", chain: nil, city: "Novi", state: "MI", zip: "48375",
                          lat: 42.48, lng: -83.47, flavors: [ "Original", "Dilly Dilly" ])
    get store_path(store)
    expect(response.body).to include("Buy at Better Health Market", "betterhealthmarket.com/jee-sauce-sauce-original-9-oz")
  end
end

RSpec.describe "Delivery links" do
  it "offers the delivery apps on the finder and on store pages" do
    store = Store.create!(rep_id: 30, name: "Boise Albertsons", chain: "Albertsons Mountain West", city: "Boise", state: "ID", zip: "83702",
                          lat: 43.6, lng: -116.2, flavors: [ "Original", "Dilly Dilly" ])
    get root_path
    Flavor::DELIVERY.each { |app| expect(response.body).to include(app[:url]) }
    get store_path(store)
    expect(response.body).to include("https://www.instacart.com/store/s?k=jeesauce")
    expect(response.body).to include("Buy at Albertsons")
    expect(response.body).to include("971387138")
  end
end
