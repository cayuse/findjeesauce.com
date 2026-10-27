require "rails_helper"

RSpec.describe StoreFeed do
  def sync = StoreFeed.new(rep_client).sync!

  it "copies the feed, normalizing states" do
    stub_rep_feed
    run = sync
    expect(run.status).to eq("ok")
    expect(Store.count).to eq(7)
    expect(Store.pluck(:state)).to all(match(/\A[A-Z]{2}\z/))
    expect(run.token_expires_at).to eq(Time.utc(2029, 10, 27))
  end

  it "removes stores that left the feed" do
    Store.create!(rep_id: 999_999, name: "Gone Market")
    stub_rep_feed
    sync
    expect(Store.where(rep_id: 999_999)).to be_empty
  end

  it "keeps the last good copy when rep fails" do
    stub_rep_feed
    sync
    stub_request(:get, "#{RepFixtures::REP}/api/v1/stores?limit=5000").with(headers: { "If-None-Match" => '"v1"' })
      .to_return(status: 503, body: "")
    run = sync
    expect(run.status).to eq("failed")
    expect(Store.count).to eq(7)
  end

  it "refuses a feed that would drop most of the stores" do
    20.times { |i| Store.create!(rep_id: 100_000 + i, name: "Store #{i}") }
    stub_rep_feed
    run = sync
    expect(run.status).to eq("refused")
    expect(Store.count).to eq(20)
  end
end
