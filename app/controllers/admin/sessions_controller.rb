# Google sign-in for /admin (GoogleSignIn). GETs only, so ReadOnly needs no
# new exception: /admin/sign-in sends you to Google with a one-time state and
# nonce; Google sends you back to /auth/google_oauth2/callback (rep's path
# convention, so it's one more redirect URI on the same client).
class Admin::SessionsController < ApplicationController
  SESSION_HOURS = 12

  before_action { raise ActionController::RoutingError, "Not Found" unless GoogleSignIn.enabled? }

  def new
    session[:google_state] = SecureRandom.urlsafe_base64(24)
    session[:google_nonce] = SecureRandom.urlsafe_base64(24)
    redirect_to GoogleSignIn.authorize_url(redirect_uri: google_callback_url, state: session[:google_state],
                                           nonce: session[:google_nonce]), allow_other_host: true
  end

  def callback
    state, nonce = session.delete(:google_state), session.delete(:google_nonce)
    return refuse("That sign-in link expired. Try again.") unless state && params[:code] &&
                                                               ActiveSupport::SecurityUtils.secure_compare(params[:state].to_s, state)

    email = GoogleSignIn.email_for(code: params[:code], redirect_uri: google_callback_url, nonce:)
    return refuse("#{email} isn't on the team list for this page.") unless GoogleSignIn.allowed?(email)

    reset_session
    session[:admin_email] = email
    session[:admin_until] = SESSION_HOURS.hours.from_now.to_i
    redirect_to admin_root_path
  rescue GoogleSignIn::Error => e
    Rails.logger.warn("Google sign-in refused: #{e.message}")
    refuse("Google sign-in didn't work. Try again.")
  end

  def destroy
    reset_session
    redirect_to root_path
  end

  private

  def refuse(message)
    render plain: "#{message}\n", status: :forbidden
  end
end
