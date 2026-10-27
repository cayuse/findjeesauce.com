# www.findjeesauce.com → findjeesauce.com (301), so search engines see one
# site. Set CANONICAL_HOST; unset (dev) = no-op. Only the www alias redirects:
# any other host is rejected earlier by Rails' host authorization.
class CanonicalHost
  def initialize(app)
    @app = app
    @host = ENV["CANONICAL_HOST"].presence
  end

  def call(env)
    request = Rack::Request.new(env)
    if @host && request.host == "www.#{@host}"
      [ 301, { "location" => "https://#{@host}#{request.fullpath}", "content-type" => "text/plain" }, [ "Moved" ] ]
    else
      @app.call(env)
    end
  end
end
