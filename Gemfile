source "https://rubygems.org"
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

ruby "3.1.0"

# Bundle edge Rails instead: gem 'rails', github: 'rails/rails', branch: 'main'
gem "rails", "~> 7.0.1"
# Use sqlite3 as the database for Active Record
gem "sqlite3", "~> 1.4"
# Use Puma as the app server
gem "puma", "~> 5.0"
# Use SCSS for stylesheets
gem "sass-rails", ">= 6"
# Build JSON APIs with ease. Read more: https://github.com/rails/jbuilder
gem "jbuilder", "~> 2.7"
# Use Redis adapter to run Action Cable in production
# gem 'redis', '~> 4.0'
# Use Active Model has_secure_password
# gem 'bcrypt', '~> 3.1.7'

# Use Active Storage variant
# gem 'image_processing', '~> 1.2'

# Reduces boot times through caching; required in config/boot.rb
gem "bootsnap", ">= 1.4.4", require: false

group :development, :test do
  # Call 'byebug' anywhere in the code to stop execution and get a debugger console
  gem "byebug", platforms: [:mri, :mingw, :x64_mingw]

  # Discover N+1 statements
  gem "bullet"

  # Jard is an improvement on Byebug
  gem "ruby_jard"
  gem "pry-byebug"

  # RuboCop is an excellent linter, we keep it in `test` for CI
  gem "rubocop", require: false
  gem "rubocop-rails", require: false # Rails specific styles
  gem "rubocop-rails_config", require: false # More Rails stuff
  gem "rubocop-performance", require: false # Performance checks
  gem "rubocop-minitest", require: false # For checking tests
end

group :development do
  # Access an interactive console on exception pages or by calling 'console' anywhere in the code.
  gem "web-console", ">= 4.1.0"
  # Display performance information such as SQL time and flame graphs for each request in your browser.
  # Can be configured to work on production as well see: https://github.com/MiniProfiler/rack-mini-profiler/blob/master/README.md
  gem "rack-mini-profiler", "~> 2.0"
  gem "listen", "~> 3.3"
  # Spring is removed here because it causes serious issues with the scrapers

  # This is required for Ruby 3 from Sorbet
  gem "sorted_set"

  # Tmuxinator lets us set up standard development environments easily
  gem "tmuxinator"

  # Yard is for documenting the code
  gem "yard", require: false
end

# Adds support for Capybara system testing and selenium driver
gem "capybara", ">= 3.26"
gem "selenium-webdriver"
# Easy installation and use of web drivers to run system tests with browsers
gem "webdrivers"

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem "tzinfo-data", platforms: [:mingw, :mswin, :x64_mingw, :jruby]

# The whole point of this app
# This is a hack to read in environment variables before Figaro is loaded and booted up, first it checks if
# it's in an environment variable (such as it'd be on Heroku or something) and if not, parses the application.yml file
#
# Why is this being done? Because otherwise the settings for Capybara (used in the gems for the scraping) get overloaded
# by the last of the gems to be loaded. So facebook.com is the home page no matter what if Forki is loaded last. We just
# want one.
differentiated_as = ENV["DIFFERENTIATED_AS"] if ENV.has_key?("DIFFERENTIATED_AS")
if differentiated_as.nil?
  require "YAML"
  differentiated_as = YAML.load(File.read("config/application.yml"))["DIFFERENTIATE_AS"]
end

case differentiated_as
when "instagram"
  gem "zorki", "0.1.0", git: "https://github.com/cguess/zorki"
when "facebook"
  gem "forki", "0.1.0", git: "https://github.com/oneroyalace/forki"
else
  raise "Invalid differentiation type: #{differentiated_as}"
end

# Figaro lets us configure and require environment variable at boot, instead of getting stuck with a
# bad deployment
gem "figaro"

# Add the ability to load `.env` files on launch
gem "dotenv-rails"

# Make JSON-ifying stuff easier
gem "blueprinter"

# Used to store settings for auth keys
gem "rails-settings-cached"

# For creating web requests
gem "typhoeus"

# New way to bundle CSS and JS for Rails 7
gem "cssbundling-rails"
gem "importmap-rails"

# Use Stimulus for Rails 7
gem "stimulus-rails"

gem "sprockets-rails", require: "sprockets/railtie"

gem "tailwindcss-rails", "~> 2.0"
