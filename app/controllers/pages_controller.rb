class PagesController < ApplicationController
  def robots
    body = if noindex?
      "User-agent: *\nDisallow: /\n"
    else
      "User-agent: *\nAllow: /\nSitemap: #{sitemap_url}\n"
    end
    render plain: body
  end

  def sitemap
    @stores = Store.order(:id)
    expires_in 1.hour, public: true
    render formats: :xml
  end
end
