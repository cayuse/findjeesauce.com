require "rails_helper"

RSpec.describe Flavor do
  it "covers every flavor H-E-B stocks" do
    expect(Flavor::HEB.keys).to match_array([ "Original", "Cilantro Lime", "Dilly Dilly", "Sun-Dried Tomato Basil" ])
  end

  it "knows each flavor by rep's name and by slug, with a lid on disk" do
    Flavor.all.each do |f|
      expect(Flavor.named(f.name)).to eq(f)
      expect(Flavor.find(f.slug)).to eq(f)
      expect(Rails.root.join("app/assets/images", f.lid)).to exist
    end
  end

  it "sorts rep's names into display order, unknown names last" do
    expect(Flavor.sort_names([ "Chipotle", "Mango", "Original" ])).to eq([ "Original", "Chipotle", "Mango" ])
  end

  it "only links chains and flavors someone checked" do
    expect(Flavor.chain_link("H-E-B", "Original")).to start_with("https://www.heb.com/product-detail/")
    expect(Flavor.chain_link("Safeway", "Original")).to be_nil
  end
end

RSpec.describe Store do
  it "has three flavor states, never two" do
    original = Flavor.named("Original")
    expect(Store.new(flavors: [ "Original" ]).flavor_state(original)).to eq(:carries)
    expect(Store.new(flavors: [ "Chipotle" ]).flavor_state(original)).to eq(:doesnt)
    expect(Store.new(flavors: []).flavor_state(original)).to eq(:unknown)
  end
end
