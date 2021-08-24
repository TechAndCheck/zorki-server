Rails.application.routes.draw do
  # For details on the DSL available within this file, see https://guides.rubyonrails.org/routing.html

  get "scrape", to: "scraper#scrape", as: "scrape", constraints: lambda { |req| req.format == :json }
end
