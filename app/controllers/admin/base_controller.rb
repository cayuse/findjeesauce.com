# The team's pages: demand map, store asks, photo approvals, link checks.
# HTTP Basic auth against ADMIN_PASSWORD (Kamal secret, admin.env); with no
# password set, /admin doesn't exist (404). Never framed, never indexed.
class Admin::BaseController < ApplicationController
  before_action :require_admin
  after_action { response.set_header("X-Robots-Tag", "noindex, nofollow") }

  private

  def require_admin
    password = ENV["ADMIN_PASSWORD"].presence
    raise ActionController::RoutingError, "Not Found" unless password

    authenticate_or_request_with_http_basic("findjeesauce admin") do |user, given|
      ActiveSupport::SecurityUtils.secure_compare(user, "jee") & ActiveSupport::SecurityUtils.secure_compare(given, password)
    end
  end
end
