require "rails_helper"

RSpec.describe Store do
  let!(:vista) { Store.create!(rep_id: 1, name: "Vista Market", city: "Vista", state: "CA", zip: "92081", lat: 33.2, lng: -117.24) }
  let!(:carlsbad) { Store.create!(rep_id: 2, name: "Carlsbad Co-op", city: "Carlsbad", state: "CA", zip: "92008", lat: 33.16, lng: -117.35) }
  let!(:austin) { Store.create!(rep_id: 3, name: "Austin H-E-B", city: "Austin", state: "TX", zip: "78701", lat: 30.27, lng: -97.74) }

  it "finds the nearest stores, closest first, within the radius" do
    near = Store.near(33.2, -117.24)
    expect(near.map(&:name)).to eq([ "Vista Market", "Carlsbad Co-op" ])
    expect(near.first.distance).to be < 1
  end

  it "matches text by ZIP, ZIP prefix, city and state" do
    expect(Store.text_search("92081")).to contain_exactly(vista)
    expect(Store.text_search("92099")).to contain_exactly(vista, carlsbad)
    expect(Store.text_search("Austin, TX")).to contain_exactly(austin)
    expect(Store.text_search("texas")).to contain_exactly(austin)
  end

  it "normalizes state spellings" do
    expect(Store.normalize_state("California")).to eq("CA")
    expect(Store.normalize_state("ca")).to eq("CA")
  end

  it "cleans ZIPs" do
    expect(Store.normalize_zip("78703-0")).to eq("78703")
    expect(Store.normalize_zip("78726-1168")).to eq("78726-1168")
    expect(Store.text_search("92081-1234")).to contain_exactly(vista)
  end

  it "uses a readable, stable URL" do
    expect(vista.to_param).to eq("1-vista-market-vista-ca")
    expect(Store.find_by_param!("1-anything")).to eq(vista)
  end
end
