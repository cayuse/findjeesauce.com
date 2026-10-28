require "rails_helper"

RSpec.describe Jpeg do
  def segment(marker, body) = [ 0xFF, marker ].pack("C2") + [ body.bytesize + 2 ].pack("n") + body

  let(:jfif) { segment(0xE0, "JFIF\0\x01\x01".b) }
  let(:exif) { segment(0xE1, "Exif\0\0GPSLatitude 30.27 N".b) }
  let(:comment) { segment(0xFE, "taken at 123 Main St".b) }
  let(:table) { segment(0xDB, "quant".b) }
  let(:scan) { segment(0xDA, "\x01\x01".b) + "PIXELS\xFF\x00MORE".b + "\xFF\xD9".b }
  let(:photo) { "\xFF\xD8".b + jfif + exif + comment + table + scan }

  it "drops EXIF, XMP and comments and keeps the picture" do
    clean = described_class.strip(photo)
    expect(clean).to eq("\xFF\xD8".b + jfif + table + scan)
    expect(clean).not_to include("GPS", "Main St")
  end

  it "cleans one photo after another (the result is never shared state)" do
    3.times { expect(described_class.strip(photo)).to eq("\xFF\xD8".b + jfif + table + scan) }
  end

  it "refuses anything that isn't a JPEG" do
    expect(described_class.strip("\x89PNG\r\n".b)).to be_nil
    expect(described_class.strip("\xFF\xD8\xFF\xE1\x00\xFF".b)).to be_nil # truncated
  end
end
