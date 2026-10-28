# The flavors the finder knows, in the order they're shown. Rep's feed names
# the flavors each store carries; this adds what a shopper needs on top: the
# lid (the icon), the jeesauce.com product page and, per chain, a product page
# on the chain's own site.
#
# Names match rep's flavor names exactly ("Sun-Dried Tomato Basil"). Shop URLs
# are the live store's product handles; the jeesauce.com rebuild 301s them.
class Flavor < Data.define(:name, :slug, :shop_url, :color)
  ALL = [
    new(name: "Original", slug: "original", color: "#48aed2",
        shop_url: "https://jeesauce.com/products/8oz-original-jee-sauce"),
    new(name: "Cilantro Lime", slug: "cilantro-lime", color: "#489636",
        shop_url: "https://jeesauce.com/products/8oz-cilantro-lime-jee-sauce"),
    new(name: "Sun-Dried Tomato Basil", slug: "sun-dried-tomato-basil", color: "#d21e24",
        shop_url: "https://jeesauce.com/products/new-layered-sun-dried-tomato-balsamic-basil"),
    new(name: "Dilly Dilly", slug: "dilly-dilly", color: "#24726c",
        shop_url: "https://jeesauce.com/products/dilly-dilly"),
    new(name: "Chipotle", slug: "chipotle", color: "#d83024",
        shop_url: "https://jeesauce.com/products/8oz-chipotle-jeesauce")
  ].freeze

  # A chain's own product page per flavor. Only links someone has opened and
  # checked go here (a dead or wrong link is worse than none); a flavor with no
  # entry gets no button. All from the owner, 2026-10-27. Albertsons' pages
  # are on albertsons.com; its sister banners (Safeway, Jewel-Osco, Pavilions)
  # have their own sites and aren't linked until someone checks them.
  HEB = {
    "Original" => "https://www.heb.com/product-detail/jeesauce-original-almond-based-dip-9-oz/16045543",
    "Sun-Dried Tomato Basil" => "https://www.heb.com/product-detail/jeesauce-sun-dried-tomato-basil-almond-based-dip-9-oz/16045547",
    "Dilly Dilly" => "https://www.heb.com/product-detail/jeesauce-dilly-dilly-almond-based-dip-9-oz/16045549",
    "Cilantro Lime" => "https://www.heb.com/product-detail/jeesauce-cilantro-lime-almond-based-dip-9-oz/16047037"
  }.freeze
  ALBERTSONS = {
    "Original" => "https://www.albertsons.com/shop/pd/jee-sauce-original-9-oz/971387138",
    "Cilantro Lime" => "https://www.albertsons.com/shop/pd/jee-sauce-cilantro-lime-9-oz/971387139"
  }.freeze
  CHAIN_LINKS = { "H-E-B" => HEB, "Albertsons" => ALBERTSONS, "Albertsons Mountain West" => ALBERTSONS }.freeze

  # How a chain's button reads: "Buy at H-E-B".
  CHAIN_LABELS = { "Albertsons Mountain West" => "Albertsons" }.freeze

  # Delivery apps, for "Get it delivered". Searches for now: the app picks a
  # store near the shopper that stocks us. An Instacart brand page (free, made
  # for this) replaces its search once someone sets it up (docs/AFFILIATE_STUDY.md).
  # No affiliate codes: if any are added, the page must say so.
  DELIVERY = [
    { name: "Instacart", url: "https://www.instacart.com/store/s?k=jeesauce", color: "#0aad0a" },
    { name: "DoorDash", url: "https://www.doordash.com/search/store/jeesauce/", color: "#ff3008" },
    { name: "Uber Eats", url: "https://www.ubereats.com/search?q=jeesauce", color: "#06c167" }
  ].freeze

  BY_NAME = ALL.index_by(&:name).freeze
  BY_SLUG = ALL.index_by(&:slug).freeze

  def lid = "lids/#{slug}.webp"

  def self.all = ALL
  def self.find(slug) = BY_SLUG[slug.to_s]
  def self.named(name) = BY_NAME[name.to_s]

  # Rep's names, in our display order; a flavor we don't know yet still shows,
  # after the known ones, as its name.
  def self.sort_names(names) = names.sort_by { |n| [ ALL.index(BY_NAME[n]) || ALL.size, n ] }

  def self.chain_link(chain, flavor_name) = CHAIN_LINKS.dig(chain, flavor_name)
  def self.chain_label(chain) = CHAIN_LABELS.fetch(chain, chain)
end
