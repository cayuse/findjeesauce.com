# Where a shopper searched, kept coarse: a typed ZIP, and the point rounded to
# 0.1° (about 7 miles). Never the search text, the exact point or the IP.
module CoarsePlace
  extend ActiveSupport::Concern

  class_methods do
    def coarse(zip: nil, lat: nil, lng: nil)
      { zip: zip.to_s[/\A\d{5}/], lat: lat&.to_f&.round(1), lng: lng&.to_f&.round(1) }
    end
  end
end
