# POST /asks: a shopper opened a chain's product-request page, or copied our
# request, from "Ask your store". Counted for the demand map; nothing typed is
# kept. Like SharesController: no session, so no CSRF token; rate-limited.
class AsksController < ApplicationController
  skip_forgery_protection
  rate_limit to: 10, within: 1.hour, by: -> { request.remote_ip }, with: -> { head :too_many_requests }

  def create
    ask = Ask.new(chain: params[:chain], flavor: Flavor.find(params[:flavor])&.name,
                  **Ask.coarse(zip: params[:zip], lat: coordinate(params[:lat], 90), lng: coordinate(params[:lng], 180)))
    ask.save ? head(:no_content) : head(:unprocessable_content)
  end

  private

  def coordinate(value, max)
    f = Float(value, exception: false)
    f if f && f.abs <= max
  end
end
