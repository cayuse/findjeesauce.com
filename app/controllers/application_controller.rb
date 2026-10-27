class ApplicationController < ActionController::Base
  # No allow_browser: shoppers on older phones must still get the list (the
  # map is extra). The pages work without JavaScript.

  # Changes to the importmap will invalidate the etag for HTML responses
  stale_when_importmap_changes

  before_action :noindex_staging
  helper_method :maps_key, :noindex?

  private

  # Staging (NOINDEX=1) must never show up in search results.
  def noindex? = ENV["NOINDEX"].present?

  def noindex_staging
    response.set_header("X-Robots-Tag", "noindex, nofollow") if noindex?
  end

  # Google Maps JavaScript API browser key: public by design, locked to our
  # hostnames in the Google Cloud console. Blank = list-only pages.
  def maps_key = ENV["GOOGLE_MAPS_BROWSER_API_KEY"].presence
end
