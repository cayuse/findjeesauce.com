# POST /clicks: a shopper clicked out to a retailer, delivery app,
# jeesauce.com or directions (track_controller.js). Counted for the team
# page; like SharesController, no session or CSRF token, rate-limited.
class ClicksController < ApplicationController
  skip_forgery_protection
  rate_limit to: 60, within: 1.hour, by: -> { request.remote_ip }, with: -> { head :too_many_requests }

  def create
    click = Click.from(host: params[:host], store_rep_id: params[:store], flavor: params[:flavor], spot: params[:spot])
    click&.save ? head(:no_content) : head(:unprocessable_content)
  end
end
