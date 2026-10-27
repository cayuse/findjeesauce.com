module RepFixtures
  REP = "https://rep.test".freeze

  def rep_fixture(name) = File.read(Rails.root.join("spec/fixtures/rep/#{name}.json"))

  # Rep serving the two recorded pages.
  def stub_rep_feed(expires: "2029-10-27T00:00:00Z", etag: '"v1"')
    stub_request(:get, "#{REP}/api/v1/stores?limit=5000")
      .with(headers: { "Authorization" => "Bearer test-token" })
      .to_return(status: 200, body: rep_fixture("stores_page1"),
                 headers: { "Content-Type" => "application/json", "ETag" => etag, "Rep-Token-Expires" => expires })
    stub_request(:get, "#{REP}/api/v1/stores?cursor=page2")
      .to_return(status: 200, body: rep_fixture("stores_page2"), headers: { "Content-Type" => "application/json" })
  end

  def rep_client = Rep::Client.new(base_url: REP, token: "test-token")
end

RSpec.configure { |c| c.include RepFixtures }
