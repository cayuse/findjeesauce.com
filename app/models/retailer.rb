# Where a shopper asks a chain to stock us (item 3). Each chain's own page for
# it; the shopper pastes our ready-made request. Checked 2026-10-28:
# H-E-B's contact form has "In-store shopping → Product request"
# (heb.com/help/in-store/how-do-i-request-a-product-to-be-added); Albertsons'
# banners go to their help pages (Contact us there).
module Retailer
  REQUESTS = {
    "heb" => { name: "H-E-B", url: "https://www.heb.com/contact-us",
               how: "Pick “In-store shopping”, then “Product request”, and paste this." },
    "albertsons" => { name: "Albertsons", url: "https://www.albertsons.com/contact-us.html",
                      how: "Choose Contact us, then paste this." },
    "safeway" => { name: "Safeway", url: "https://www.safeway.com/contact-us.html",
                   how: "Choose Contact us, then paste this." },
    "jewelosco" => { name: "Jewel-Osco", url: "https://www.jewelosco.com/contact-us.html",
                     how: "Choose Contact us, then paste this." }
  }.freeze

  def self.requests = REQUESTS.reject { |_, r| LinkCheck.broken?(r[:url]) }

  # The request a shopper pastes or shows the manager. UPCs let the buyer
  # find us in their distributor's catalog.
  def self.request_text(flavor = nil)
    flavors = flavor ? [ flavor ] : Flavor.all
    lines = flavors.map { |f| "#{f.name} (UPC #{f.upc})" }
    <<~TEXT.strip
      Hi! Please stock JeeSauce whipped almond hummus, a 9 oz refrigerated dip.
      #{flavors.one? ? "Flavor" : "Flavors"}: #{lines.join(', ')}.
      It's available through KeHE and UNFI. More at jeesauce.com. Thank you!
    TEXT
  end
end
