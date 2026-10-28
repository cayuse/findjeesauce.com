require "net/http"

# The last check of one outside link (item 6). LinkCheck.run! checks every
# link the finder shows; Flavor and the views ask LinkCheck.broken?(url).
class LinkCheck < ApplicationRecord
  MISSES_TO_HIDE = 2
  BROKEN = [ 404, 410 ].freeze
  USER_AGENT = "Mozilla/5.0 (compatible; findjeesauce-linkcheck/1.0; +https://findjeesauce.com)".freeze

  def self.urls
    (Flavor::CHAIN_LINKS.values.flat_map(&:values) + Flavor::RETAILERS.pluck(:url) +
      Flavor::DELIVERY.pluck(:url) + Retailer::REQUESTS.values.pluck(:url)).uniq
  end

  # Hidden links, read once per request (a handful of rows).
  def self.broken?(url) = broken_urls.include?(url)

  def self.broken_urls
    Current.broken_urls ||= where(result: "broken").where(misses: MISSES_TO_HIDE..).pluck(:url).to_set
  end

  def self.run!(urls = self.urls)
    urls.each { |url| check!(url) }
  end

  def self.check!(url)
    code, error = fetch(url)
    result = if code&.between?(200, 399) then "ok"
    elsif BROKEN.include?(code) then "broken"
    else "unsure" # bot walls (403, 429), outages, timeouts prove nothing
    end
    row = find_or_initialize_by(url:)
    row.update!(status_code: code, result:, error:, checked_at: Time.current,
                misses: result == "broken" ? row.misses + 1 : (result == "ok" ? 0 : row.misses),
                last_ok_at: result == "ok" ? Time.current : row.last_ok_at)
    row
  end

  # [status code, error]; follows up to 5 redirects.
  def self.fetch(url, redirects: 5)
    uri = URI(url)
    redirects.downto(0) do
      response = Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == "https", open_timeout: 10, read_timeout: 15) do |http|
        http.request(Net::HTTP::Get.new(uri, "User-Agent" => USER_AGENT, "Accept" => "text/html"))
      end
      return [ response.code.to_i, nil ] unless response.is_a?(Net::HTTPRedirection) && response["location"]

      uri = URI.join(uri, response["location"])
    end
    [ nil, "too many redirects" ]
  rescue StandardError => e
    [ nil, "#{e.class}: #{e.message}".first(200) ]
  end
end
