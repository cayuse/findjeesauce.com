require "rails_helper"

RSpec.describe Rep::Client do
  it "follows meta.next and returns every row with the headers' metadata" do
    stub_rep_feed
    feed = rep_client.stores
    expect(feed.rows.size).to eq(7)
    expect(feed.etag).to eq('"v1"')
    expect(feed.token_expires_at).to eq(Time.utc(2029, 10, 27))
    expect(feed.not_modified).to be(false)
  end

  it "sends If-None-Match and reports a 304 as not modified" do
    stub_request(:get, "#{RepFixtures::REP}/api/v1/stores?limit=5000")
      .with(headers: { "If-None-Match" => '"v1"' }).to_return(status: 304)
    expect(rep_client.stores(etag: '"v1"').not_modified).to be(true)
  end

  it "raises with rep's error code" do
    stub_request(:get, "#{RepFixtures::REP}/api/v1/stores?limit=5000")
      .to_return(status: 401, body: { error: { code: "token_expired", message: "Expired." } }.to_json)
    expect { rep_client.stores }.to raise_error(Rep::Client::Error) { |e| expect(e.code).to eq("token_expired") }
  end

  it "raises when rep is unreachable" do
    stub_request(:get, "#{RepFixtures::REP}/api/v1/stores?limit=5000").to_timeout
    expect { rep_client.stores }.to raise_error(Rep::Client::Error, /unreachable/)
  end
end
