Rails.application.routes.draw do
  # Load balancer / kamal-proxy health check: 200 when the app boots.
  get "up" => "rails/health#show", as: :rails_health_check

  root "stores#index"
  resources :stores, only: :show

  # The same finder without our header and footer, for jeesauce.com to frame
  # (its store-locator page). Only jeesauce.com and Shopify's previews may
  # frame it (ApplicationController#allow_framing).
  scope "embed", as: "embed", defaults: { embed: "1" } do
    get "/", to: "stores#index", as: :root
    resources :stores, only: :show
  end

  # The public copy jeesauce.com embeds (Shopify theme, later the headless site).
  get "stores", to: "feeds#stores", constraints: { format: "json" }, as: :stores_feed

  get "robots.txt", to: "pages#robots", format: false
  get "sitemap.xml", to: "pages#sitemap", format: false
end
