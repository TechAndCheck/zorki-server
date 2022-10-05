require "capybara/dsl"
require "selenium-webdriver"

# For screenshotting we're using Firefox instead of Chrome. This is because Chrome
# cannot take full page screenshots.
# options = Selenium::WebDriver::Firefox::Options.new
options = Selenium::WebDriver::Chrome::Options.new
options.add_argument("--window-size=1400,1400")
options.add_argument("--no-sandbox")
options.add_argument("--disable-dev-shm-usage")
options.add_argument("--user-data-dir=/tmp/tarun_hypatia_#{SecureRandom.uuid}")

# Here we assume we're using the same locally running scraping server that the gems would
# be set to. This should be configurable if we ever get bigger
Capybara.register_driver :hypatia do |app|
  client = Selenium::WebDriver::Remote::Http::Default.new
  client.read_timeout = 60  # Don't wait 60 seconds to return Net::ReadTimeoutError. We'll retry through Hypatia after 10 seconds
  Capybara::Selenium::Driver.new(app, browser: :chrome, url: "http://localhost:4444/wd/hub", capabilities: options, http_client: client)
end

Capybara.threadsafe = true
Capybara.default_max_wait_time = 60
Capybara.reuse_server = true
Capybara.default_driver = :hypatia
