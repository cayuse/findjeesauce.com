require "rails_helper"

BROWSER = { "User-Agent" => "Mozilla/5.0 (iPhone) Safari" }.freeze

RSpec.describe "Demand map: searches" do
  let!(:store) { Store.create!(rep_id: 50, name: "Austin H-E-B", chain: "H-E-B", city: "Austin", state: "TX", zip: "78701", lat: 30.27, lng: -97.74, flavors: [ "Original" ]) }

  it "logs a coarse row per search, and nothing for robots" do
    get root_path, params: { lat: 30.2712, lng: -97.7431, flavor: "chipotle" }, headers: BROWSER
    expect(Search.last).to have_attributes(lat: 30.3, lng: -97.7, zip: nil, flavor: "Chipotle", nearby_count: 1, carrier_count: 0, state: "TX")
    get root_path, params: { q: "78701" }, headers: { "User-Agent" => "Googlebot/2.1" }
    expect(Search.count).to eq(1)
  end

  it "counts a search far from any store as empty" do
    get root_path, params: { lat: 42.33, lng: -83.05 }, headers: BROWSER
    expect(Search.last).to have_attributes(nearby_count: 0, lat: 42.3)
  end
end

RSpec.describe "Ask your store" do
  it "shows the request with UPCs when nothing is near" do
    get root_path, params: { lat: 42.33, lng: -83.05 }, headers: BROWSER
    expect(response.body).to include("Not near you yet? Ask your store.", "854182007858", "https://www.heb.com/contact-us")
  end

  it "asks one store for the missing flavor" do
    store = Store.create!(rep_id: 51, name: "Austin H-E-B", chain: "H-E-B", city: "Austin", state: "TX", zip: "78701", lat: 30.27, lng: -97.74, flavors: [ "Original" ])
    get store_path(store, flavor: "dilly-dilly")
    expect(response.body).to include("Ask this store for Dilly Dilly", "Dilly Dilly (UPC 854182007919)")
  end

  it "counts an ask by chain and coarse place" do
    post asks_path, params: { chain: "heb", flavor: "chipotle", zip: "78701", lat: "30.2712", lng: "-97.7431" }
    expect(response).to have_http_status(:no_content)
    expect(Ask.last).to have_attributes(chain: "heb", flavor: "Chipotle", zip: "78701", lat: 30.3)
    post asks_path, params: { chain: "evil.example" }
    expect(response).to have_http_status(:unprocessable_content)
  end
end

RSpec.describe "I found it" do
  around do |ex|
    ENV["SIGHTING_PHOTOS"] = "1"
    ex.run
  ensure
    ENV.delete("SIGHTING_PHOTOS")
  end

  let!(:store) { Store.create!(rep_id: 52, name: "Austin H-E-B", chain: "H-E-B", city: "Austin", state: "TX", zip: "78701", lat: 30.27, lng: -97.74, flavors: [ "Original" ]) }
  let(:jpeg) do
    exif = "\xFF\xE1".b + [ 14 ].pack("n") + "Exif\0\0GPS123".b
    Rack::Test::UploadedFile.new(StringIO.new("\xFF\xD8".b + exif + "\xFF\xDA\x00\x02PIXELS\xFF\xD9".b), "image/jpeg", true, original_filename: "x.jpg")
  end

  it "records a sighting and shows it as fresh" do
    post store_sightings_path(store), params: { flavor: "original" }
    expect(response).to redirect_to(store_path(store, found: "1", anchor: "found"))
    follow_redirect!
    expect(response.body).to include("Thanks! You just helped", "Spotted by a shopper today")
  end

  it "keeps a photo, stripped and hidden, until it's approved" do
    post store_sightings_path(store), params: { photo: jpeg, photo_ok: "1" }
    sighting = Sighting.last
    expect(sighting.photo_status).to eq("pending")
    expect(sighting.photo).not_to include("GPS")
    get sighting_photo_path(sighting)
    expect(response).to have_http_status(:not_found)
    sighting.approve!
    get sighting_photo_path(sighting)
    expect(response.media_type).to eq("image/jpeg")
    get store_path(store)
    expect(response.body).to include(sighting_photo_path(sighting))
  end

  it "ignores a photo sent without the OK box, and refuses a non-JPEG" do
    post store_sightings_path(store), params: { photo: jpeg }
    expect(Sighting.last.photo_status).to eq("none")
    png = Rack::Test::UploadedFile.new(StringIO.new("\x89PNG\r\n".b), "image/png", true, original_filename: "x.png")
    expect { post store_sightings_path(store), params: { photo: png, photo_ok: "1" } }.not_to change(Sighting, :count)
    expect(response).to redirect_to(store_path(store, found: "bad", anchor: "found"))
  end
end

RSpec.describe "Freshness" do
  it "shows rep's shelf signal as this month, never a date" do
    store = Store.create!(rep_id: 53, name: "Boise Albertsons", city: "Boise", state: "ID", zip: "83702", lat: 43.6, lng: -116.2,
                          flavors: [ "Original" ], stocked_recently: true)
    travel_to Time.zone.parse("2026-11-03 12:00") do
      get store_path(store)
      expect(response.body).to include("In stock: November")
    end
    store.update!(stocked_recently: false)
    get store_path(store)
    expect(response.body).not_to include("In stock:")
  end
end

RSpec.describe "Team pages" do
  let(:auth) { { "HTTP_AUTHORIZATION" => ActionController::HttpAuthentication::Basic.encode_credentials("jee", "s3cret") } }

  around do |ex|
    old = ENV["ADMIN_PASSWORD"]
    ENV["ADMIN_PASSWORD"] = "s3cret"
    ex.run
  ensure
    ENV["ADMIN_PASSWORD"] = old
  end

  it "needs the password" do
    get admin_root_path
    expect(response).to have_http_status(:unauthorized)
    get admin_root_path, headers: auth
    expect(response.body).to include("Where shoppers want JeeSauce")
    get admin_demand_path(format: :csv), headers: auth
    expect(response.body).to start_with("lat,lng,zip")
  end

  it "doesn't exist without a password set" do
    ENV["ADMIN_PASSWORD"] = ""
    get admin_root_path, headers: auth
    expect(response).to have_http_status(:not_found)
  end

  it "approves and rejects photos" do
    a = Sighting.create!(store_rep_id: 1, photo: "x", photo_status: "pending")
    b = Sighting.create!(store_rep_id: 1, photo: "y", photo_status: "pending")
    get admin_sightings_path, headers: auth
    expect(response.body).to include(photo_admin_sighting_path(a))
    post approve_admin_sighting_path(a), headers: auth
    post reject_admin_sighting_path(b), headers: auth
    expect(a.reload.photo_status).to eq("approved")
    expect(b.reload).to have_attributes(photo_status: "rejected", photo: nil)
  end
end

RSpec.describe LinkCheck do
  let(:url) { Flavor::HEB["Original"] }

  it "hides a link after two definite misses, and never for a bot wall" do
    stub_request(:get, url).to_return(status: 403)
    2.times { described_class.check!(url) }
    expect(described_class.find_by(url:).result).to eq("unsure")
    expect(Flavor.chain_link("H-E-B", "Original")).to eq(url)

    stub_request(:get, url).to_return(status: 404)
    described_class.check!(url)
    Current.reset
    expect(Flavor.chain_link("H-E-B", "Original")).to eq(url)
    described_class.check!(url)
    Current.reset
    expect(Flavor.chain_link("H-E-B", "Original")).to be_nil

    stub_request(:get, url).to_return(status: 301, headers: { "Location" => "/moved" })
    stub_request(:get, "https://www.heb.com/moved").to_return(status: 200)
    described_class.check!(url)
    Current.reset
    expect(Flavor.chain_link("H-E-B", "Original")).to eq(url)
  end
end

RSpec.describe "Photos switched off" do
  let!(:store) { Store.create!(rep_id: 54, name: "Austin H-E-B", chain: "H-E-B", city: "Austin", state: "TX", zip: "78701", lat: 30.27, lng: -97.74, flavors: [ "Original" ]) }

  it "has no photo field and ignores a photo sent anyway" do
    get store_path(store)
    expect(response.body).not_to include('type="file"')
    photo = Rack::Test::UploadedFile.new(StringIO.new("\xFF\xD8\xFF\xDA\x00\x02PIX\xFF\xD9".b), "image/jpeg", true, original_filename: "x.jpg")
    post store_sightings_path(store), params: { photo:, photo_ok: "1" }
    expect(Sighting.last).to have_attributes(photo_status: "none", photo: nil)
  end
end

RSpec.describe "Sharing by channel" do
  let!(:store) { Store.create!(rep_id: 55, name: "Austin H-E-B", chain: "H-E-B", city: "Austin", state: "TX", zip: "78701", lat: 30.27, lng: -97.74, flavors: [ "Original" ]) }

  it "writes a message per channel, each link tagged with it" do
    get store_path(store)
    expect(response.body).to include("https://wa.me/?text=", "via%3Dwhatsapp", "via%3Dtext", "via%3Demail", "via=link")
    expect(response.body).to include("You%20have%20to%20try") # the email greeting
  end

  it "counts a friend's open by channel, and not a robot's" do
    get store_path(store, shared: 1, via: "whatsapp"), headers: BROWSER
    get store_path(store, shared: 1, via: "nonsense"), headers: BROWSER
    get store_path(store, shared: 1, via: "text"), headers: { "User-Agent" => "facebookexternalhit/1.1 preview" }
    expect(ShareOpen.pluck(:channel)).to eq(%w[whatsapp unknown])
  end

  it "counts a WhatsApp share" do
    post store_shares_path(store), params: { channel: "whatsapp" }
    expect(Share.last.channel).to eq("whatsapp")
  end

  it "invites the first 100" do
    get root_path
    expect(response.body).to include("Be one of the first 100")
  end
end

RSpec.describe "jeesauce.com first, and buy clicks" do
  let!(:store) { Store.create!(rep_id: 56, name: "Austin H-E-B", chain: "H-E-B", city: "Austin", state: "TX", zip: "78701", lat: 30.27, lng: -97.74, flavors: [ "Original" ]) }

  it "puts a tagged jeesauce.com tile on store pages" do
    get store_path(store, flavor: "original")
    expect(response.body).to include("Ships to your door from jeesauce.com",
                                     "8oz-original-jee-sauce?utm_campaign=find_jeesauce&amp;utm_content=store-page-tile&amp;utm_medium=store_finder&amp;utm_source=findjeesauce")
  end

  it "counts a click by where it went, and nothing for a host we don't know" do
    post clicks_path, params: { host: "www.heb.com", store: "56", flavor: "original" }
    expect(Click.last).to have_attributes(kind: "chain", target: "H-E-B", store_rep_id: 56, flavor: "Original")
    post clicks_path, params: { host: "jeesauce.com", spot: "finder-tile" }
    expect(Click.last).to have_attributes(kind: "dtc", spot: "finder-tile")
    post clicks_path, params: { host: "evil.example" }
    expect(response).to have_http_status(:unprocessable_content)
    expect(Click.count).to eq(2)
  end
end

RSpec.describe "Google sign-in for the team pages" do
  around do |ex|
    env = { "ADMIN_GOOGLE_SIGN_IN" => "1", "GOOGLE_OAUTH_CLIENT_ID" => "cid", "GOOGLE_OAUTH_CLIENT_SECRET" => "sec", "ADMIN_PASSWORD" => "s3cret" }
    old = env.keys.index_with { ENV[_1] }
    env.each { ENV[_1] = _2 }
    ex.run
  ensure
    old.each { |k, v| v ? ENV[k] = v : ENV.delete(k) }
  end

  def sign_in_as(email, verified: true, aud: "cid")
    get admin_sign_in_path
    query = Rack::Utils.parse_query(URI(response.location).query)
    claims = { aud:, iss: "https://accounts.google.com", exp: 1.hour.from_now.to_i, nonce: query["nonce"], email:, email_verified: verified }
    id_token = [ "h", Base64.urlsafe_encode64(claims.to_json, padding: false), "s" ].join(".")
    stub_request(:post, "https://oauth2.googleapis.com/token").to_return(body: { id_token: }.to_json, headers: { "Content-Type" => "application/json" })
    get google_callback_path, params: { code: "c", state: query["state"] }
  end

  it "sends you to Google, then lets the team in" do
    get admin_root_path
    expect(response).to redirect_to(admin_sign_in_path)
    sign_in_as("Joel@JeeSauce.com")
    expect(response).to redirect_to(admin_root_path)
    follow_redirect!
    expect(response.body).to include("Signed in as joel@jeesauce.com")
  end

  it "refuses anyone not on the list, an unverified email, or a token for another app" do
    sign_in_as("someone@jeesauce.com")
    expect(response).to have_http_status(:forbidden)
    sign_in_as("dave@jeesauce.com", verified: false)
    expect(response).to have_http_status(:forbidden)
    sign_in_as("dave@jeesauce.com", aud: "other")
    expect(response).to have_http_status(:forbidden)
    get admin_root_path
    expect(response).to redirect_to(admin_sign_in_path)
  end

  it "refuses a callback without the state it issued" do
    get admin_sign_in_path
    get google_callback_path, params: { code: "c", state: "forged" }
    expect(response).to have_http_status(:forbidden)
  end

  it "no longer takes the password once Google is on" do
    get admin_root_path, headers: { "HTTP_AUTHORIZATION" => ActionController::HttpAuthentication::Basic.encode_credentials("jee", "s3cret") }
    expect(response).to redirect_to(admin_sign_in_path)
  end
end
