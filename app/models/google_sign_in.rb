require "net/http"

# "Sign in with Google" for the team pages, without a gem: the standard
# OpenID Connect code flow. The ID token comes straight from Google's token
# endpoint over TLS (the server-side flow), so its claims are trusted without
# a signature check (OpenID Connect Core 3.1.3.7); we still check audience,
# issuer, expiry, nonce and that Google verified the email.
#
# Uses rep's OAuth client (Internal type: only our Workspace org,
# jeesauce.com + goodlovinfoods.com, can sign in at all), plus our own list
# of who may see the team pages (ADMIN_EMAILS).
module GoogleSignIn
  AUTH = "https://accounts.google.com/o/oauth2/v2/auth".freeze
  TOKEN = URI("https://oauth2.googleapis.com/token").freeze
  ISSUERS = %w[https://accounts.google.com accounts.google.com].freeze
  TEAM = %w[dave@jeesauce.com joel@jeesauce.com ryan@goodlovinfoods.com porter@jeesauce.com
            stephen@jeesauce.com jack@jeesauce.com].freeze

  Error = Class.new(StandardError)

  # On only when ADMIN_GOOGLE_SIGN_IN=1 and rep's client is in the env: the
  # redirect URIs must be added to that client first (docs/FINDER_EXTRAS.md).
  def self.enabled? = ENV["ADMIN_GOOGLE_SIGN_IN"] == "1" && client_id.present? && client_secret.present?
  def self.client_id = ENV["GOOGLE_OAUTH_CLIENT_ID"]
  def self.client_secret = ENV["GOOGLE_OAUTH_CLIENT_SECRET"]

  def self.team = (ENV["ADMIN_EMAILS"].presence&.split(/[\s,]+/) || TEAM).map(&:downcase)
  def self.allowed?(email) = team.include?(email.to_s.downcase)

  def self.authorize_url(redirect_uri:, state:, nonce:)
    "#{AUTH}?#{{ client_id:, redirect_uri:, response_type: 'code', scope: 'openid email', state:, nonce:,
                 prompt: 'select_account' }.to_query}"
  end

  # The verified email for an authorization code, or Error.
  def self.email_for(code:, redirect_uri:, nonce:)
    response = Net::HTTP.post_form(TOKEN, code:, client_id:, client_secret:, redirect_uri:, grant_type: "authorization_code")
    raise Error, "token exchange failed (#{response.code})" unless response.is_a?(Net::HTTPSuccess)

    claims = JSON.parse(Base64.urlsafe_decode64(JSON.parse(response.body).fetch("id_token").split(".")[1].then { |p| p + "=" * (-p.size % 4) }))
    raise Error, "wrong audience" unless claims["aud"] == client_id
    raise Error, "wrong issuer" unless ISSUERS.include?(claims["iss"])
    raise Error, "expired" unless claims["exp"].to_i > Time.now.to_i
    raise Error, "nonce mismatch" unless ActiveSupport::SecurityUtils.secure_compare(claims["nonce"].to_s, nonce.to_s)
    raise Error, "email not verified" unless claims["email_verified"] == true

    claims["email"].downcase
  end
end
