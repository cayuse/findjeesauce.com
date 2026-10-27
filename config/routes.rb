Rails.application.routes.draw do
  # Load balancer / kamal-proxy health check: 200 when the app boots.
  get "up" => "rails/health#show", as: :rails_health_check

  root "stores#index"
  resources :stores, only: :show

  # The public copy jeesauce.com embeds (Shopify theme, later the headless site).
  get "stores", to: "feeds#stores", constraints: { format: "json" }, as: :stores_feed

  get "robots.txt", to: "pages#robots", format: false
  get "sitemap.xml", to: "pages#sitemap", format: false
end
