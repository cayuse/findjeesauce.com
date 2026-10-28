# findjeesauce is READ-ONLY to the world [owner, 2026-10-27]: no create,
# update or delete of any kind, ever. Every request that isn't GET or HEAD is
# refused here, before routing, so no route or form can add one by accident.
# (The only writes are the app's own copy of the store list, made by the
# background sync from rep, never by a request.)
#
# Exceptions [Joel, 2026-10-28; flagged for cayuse to review or veto], POST
# only, each to exactly these paths, each rate-limited per IP in its
# controller:
# - /stores/:id/shares     "Spread the love" counter: store id, channel, time.
# - /stores/:id/sightings  "I found it!": store, flavor, optional JPEG photo
#                          (metadata stripped, hidden until approved).
# - /asks                  "Ask your store": chain, flavor, coarse place.
# - /clicks                buy-button clicks: where to, store, flavor.
# - /admin/sightings/:id/(approve|reject)  photo approvals, behind Basic auth
#                          and Rails' CSRF token.
# Nothing a visitor types (no names, emails, messages) is kept anywhere.
class ReadOnly
  ALLOWED = %w[GET HEAD].freeze
  POSTS = [
    %r{\A/stores/[^/]+/shares\z},
    %r{\A/stores/[^/]+/sightings\z},
    %r{\A/asks\z},
    %r{\A/clicks\z},
    %r{\A/admin/sightings/\d+/(approve|reject)\z}
  ].freeze

  def initialize(app) = @app = app

  def call(env)
    return @app.call(env) if ALLOWED.include?(env["REQUEST_METHOD"])
    return @app.call(env) if env["REQUEST_METHOD"] == "POST" && POSTS.any? { |path| env["PATH_INFO"].match?(path) }

    [ 405, { "allow" => ALLOWED.join(", "), "content-type" => "text/plain" }, [ "Read-only site.\n" ] ]
  end
end
