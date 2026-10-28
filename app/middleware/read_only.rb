# findjeesauce is READ-ONLY to the world [owner, 2026-10-27]: no create,
# update or delete of any kind, ever. Every request that isn't GET or HEAD is
# refused here, before routing, so no route or form can add one by accident.
# (The only writes are the app's own copy of the store list, made by the
# background sync from rep, never by a request.)
#
# ONE exception [Joel, 2026-10-28; flagged for cayuse]: POST
# /stores/:id/shares, the "Spread the love" counter. It adds one row (rep's
# store id, how it was shared, when): no text, no email address, nothing a
# visitor typed. Rate-limited per IP in SharesController. Nothing else.
class ReadOnly
  ALLOWED = %w[GET HEAD].freeze
  SHARE = %r{\A/stores/[^/]+/shares\z}

  def initialize(app) = @app = app

  def call(env)
    return @app.call(env) if ALLOWED.include?(env["REQUEST_METHOD"])
    return @app.call(env) if env["REQUEST_METHOD"] == "POST" && env["PATH_INFO"].match?(SHARE)

    [ 405, { "allow" => ALLOWED.join(", "), "content-type" => "text/plain" }, [ "Read-only site.\n" ] ]
  end
end
