# findjeesauce is READ-ONLY to the world [owner, 2026-10-27]: no create,
# update or delete of any kind, ever. Every request that isn't GET or HEAD is
# refused here, before routing, so no route or form can add one by accident.
# (The only writes are the app's own copy of the store list, made by the
# background sync from rep, never by a request.)
class ReadOnly
  ALLOWED = %w[GET HEAD].freeze

  def initialize(app) = @app = app

  def call(env)
    return @app.call(env) if ALLOWED.include?(env["REQUEST_METHOD"])

    [ 405, { "allow" => ALLOWED.join(", "), "content-type" => "text/plain" }, [ "Read-only site.\n" ] ]
  end
end
