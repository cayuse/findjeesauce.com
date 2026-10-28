# The team's pages: demand map, store asks, clicks, photo approvals, link
# checks. Google sign-in for the team list when GoogleSignIn.enabled?;
# until then HTTP Basic against ADMIN_PASSWORD (admin.env). With neither,
# /admin doesn't exist (404). Never framed, never indexed.
class Admin::BaseController < ApplicationController
  before_action :require_admin
  after_action { response.set_header("X-Robots-Tag", "noindex, nofollow") }

  private

  def require_admin
    return require_google if GoogleSignIn.enabled?

    password = ENV["ADMIN_PASSWORD"].presence
    raise ActionController::RoutingError, "Not Found" unless password

    authenticate_or_request_with_http_basic("findjeesauce admin") do |user, given|
      ActiveSupport::SecurityUtils.secure_compare(user, "jee") & ActiveSupport::SecurityUtils.secure_compare(given, password)
    end
  end

  def require_google
    email = session[:admin_email]
    return if email && GoogleSignIn.allowed?(email) && session[:admin_until].to_i > Time.now.to_i

    reset_session
    redirect_to admin_sign_in_path
  end
end
