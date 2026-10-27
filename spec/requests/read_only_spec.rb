require "rails_helper"

RSpec.describe "Read-only site" do
  %i[post put patch delete].each do |verb|
    it "refuses #{verb.upcase} everywhere" do
      [ "/", "/stores.json", "/stores/1-x", "/nope" ].each do |path|
        send(verb, path)
        expect(response).to have_http_status(:method_not_allowed)
        expect(response.headers["allow"]).to eq("GET, HEAD")
      end
    end
  end

  it "has no routes but GET" do
    verbs = Rails.application.routes.routes.map(&:verb).reject(&:blank?).flat_map { |v| v.split("|") }.uniq
    expect(verbs - %w[GET]).to be_empty
  end
end
