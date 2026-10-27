require "net/http"

module Rep
  # The one door to rep's API (jeehq DATA_API_CONVENTIONS §8). Server-side
  # only: the token never leaves this process. Contract: rep's
  # docs/api/rep-api.yaml; tokens: rep's docs/API_CLIENTS_AND_TOKENS.md.
  class Client
    class Error < StandardError
      attr_reader :status, :code

      def initialize(message, status: nil, code: nil)
        super(message)
        @status = status
        @code = code
      end
    end

    # Everything the stores route returned: rows from every page, and what
    # the headers said.
    Feed = Data.define(:rows, :etag, :as_of, :token_expires_at, :not_modified)

    PAGE_LIMIT = 5000 # rep's maximum: one page for today's few hundred stores
    TIMEOUT = 20

    def self.default
      new(base_url: ENV.fetch("REP_API_URL"), token: ENV.fetch("REP_API_TOKEN"))
    end

    def initialize(base_url:, token:)
      @base = URI(base_url)
      @token = token
    end

    # All stores, following meta.next. With etag: a 304 on the first page
    # returns a not_modified Feed and no rows.
    def stores(etag: nil)
      path = "/api/v1/stores?limit=#{PAGE_LIMIT}"
      rows = []
      first = nil
      while path
        res = get(path, etag: (etag if first.nil?))
        if res.is_a?(Net::HTTPNotModified)
          return Feed.new(rows: [], etag: etag, as_of: nil, token_expires_at: expires(res), not_modified: true)
        end

        body = JSON.parse(res.body)
        first ||= [ res, body ]
        rows.concat(body.fetch("data"))
        path = body.dig("meta", "next")
      end
      res, body = first
      Feed.new(rows: rows, etag: res["ETag"], as_of: time(body.dig("meta", "as_of")),
               token_expires_at: expires(res), not_modified: false)
    end

    private

    def get(path, etag: nil)
      uri = @base + path
      req = Net::HTTP::Get.new(uri)
      req["Authorization"] = "Bearer #{@token}"
      req["Accept"] = "application/json"
      req["If-None-Match"] = etag if etag.present?
      res = Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == "https",
                            open_timeout: TIMEOUT, read_timeout: TIMEOUT) { |http| http.request(req) }
      return res if res.is_a?(Net::HTTPSuccess) || res.is_a?(Net::HTTPNotModified)

      error = (JSON.parse(res.body)["error"] rescue nil) || {}
      raise Error.new("rep #{res.code} #{error['code']}: #{error['message'] || res.message}",
                      status: res.code.to_i, code: error["code"])
    rescue SocketError, SystemCallError, Net::OpenTimeout, Net::ReadTimeout, OpenSSL::SSL::SSLError => e
      raise Error.new("rep unreachable: #{e.class}: #{e.message}")
    end

    # Rep-Token-Expires (API_CLIENTS_AND_TOKENS.md), when rep sends it.
    def expires(res) = time(res["Rep-Token-Expires"])

    def time(value)
      value.present? ? Time.iso8601(value) : nil
    rescue ArgumentError
      nil
    end
  end
end
