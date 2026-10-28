Rails.application.routes.draw do
  # Load balancer / kamal-proxy health check: 200 when the app boots.
  get "up" => "rails/health#show", as: :rails_health_check

  root "stores#index"
  resources :stores, only: :show do
    # The "Spread the love" counter: one per press of a share button.
    resources :shares, only: :create
    # "I found it!", with an optional photo for approval.
    resources :sightings, only: :create
  end
  get "sightings/:id/photo", to: "sightings#photo", as: :sighting_photo
  # "Ask your store": counted for the demand map.
  resources :asks, only: :create
  # Clicks out to retailers, delivery apps, jeesauce.com, directions.
  resources :clicks, only: :create

  # The team's pages (Basic auth; see Admin::BaseController).
  get "auth/google_oauth2/callback", to: "admin/sessions#callback", as: :google_callback
  namespace :admin do
    root "dashboard#show"
    get "sign-in", to: "sessions#new", as: :sign_in
    get "sign-out", to: "sessions#destroy", as: :sign_out
    get "demand", to: "dashboard#show", as: :demand
    resources :sightings, only: :index do
      member do
        get :photo
        post :approve
        post :reject
      end
    end
  end

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
