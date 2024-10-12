Rails.application.routes.draw do
  # For details on the DSL available within this file, see https://guides.rubyonrails.org/routing.html

  defaults format: :json do
    post "scrape", to: "scraper#scrape", as: "scrape", constraints: lambda { |req| req.format == :json }
    get "heartbeat", to: "scraper#heartbeat", as: "heartbeat"
  end
end
