class ApplicationController < ActionController::Base
  # No allow_browser: shoppers on older phones must still get the list (the
  # map is extra). The pages work without JavaScript.

  # Changes to the importmap will invalidate the etag for HTML responses
  stale_when_importmap_changes

  # Who may show the /embed pages in a frame: jeesauce.com (live Shopify
  # theme, later the headless site), its staging, and Shopify's theme preview
  # and editor. Every other page refuses to be framed (Rails' default
  # X-Frame-Options: SAMEORIGIN).
  FRAME_ANCESTORS = %w[
    https://jeesauce.com https://www.jeesauce.com https://jeesauce-com.myshopify.com
    https://*.shopifypreview.com https://admin.shopify.com https://jeesauce.cavaforge.net
  ].freeze

  before_action :noindex_staging
  before_action :allow_framing, if: :embed?
  layout -> { embed? ? "embed" : "application" }
  helper_method :maps_key, :noindex?, :embed?, :finder_root_path, :finder_store_path

  private

  # Staging (NOINDEX=1) must never show up in search results.
  def noindex? = ENV["NOINDEX"].present?

  def noindex_staging
    response.set_header("X-Robots-Tag", "noindex, nofollow") if noindex?
  end

  # Google Maps JavaScript API browser key: public by design, locked to our
  # hostnames in the Google Cloud console. Blank = list-only pages.
  def maps_key = ENV["GOOGLE_MAPS_BROWSER_API_KEY"].presence

  def embed? = params[:embed] == "1"

  def allow_framing
    response.headers.delete("X-Frame-Options")
    response.set_header("Content-Security-Policy", "frame-ancestors 'self' #{FRAME_ANCESTORS.join(' ')}")
  end

  # Links stay inside the frame on /embed pages, on the full site elsewhere.
  def finder_root_path(...) = embed? ? embed_root_path(...) : root_path(...)
  def finder_store_path(store, ...) = embed? ? embed_store_path(store, ...) : store_path(store, ...)
end
