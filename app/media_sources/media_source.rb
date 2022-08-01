require "capybara/dsl"
class MediaSource
  include Capybara::DSL
  include Slack

  @@logger = Logger.new(STDOUT)
  @@logger.level = Logger::DEBUG
  @@logger.datetime_format = "%Y-%m-%d %H:%M:%S"

  # For screenshotting we're using Firefox instead of Chrome. This is because Chrome
  # cannot take full page screenshots.
  options = Selenium::WebDriver::Firefox::Options.new
  options.add_argument("--window-size=1400,1400")
  options.add_argument("--no-sandbox")
  options.add_argument("--disable-dev-shm-usage")
  options.add_argument("--user-data-dir=/tmp/tarun")

  # Here we assume we're using the same locally running scraping server that the gems would
  # be set to. This should be configurable if we ever get bigger
  Capybara.register_driver :firefox_hypatia do |app|
    client = Selenium::WebDriver::Remote::Http::Default.new
    client.read_timeout = 60  # Don't wait 60 seconds to return Net::ReadTimeoutError. We'll retry through Hypatia after 10 seconds
    Capybara::Selenium::Driver.new(app, browser: :firefox, url: "http://localhost:4444/wd/hub", capabilities: options, http_client: client)
  end

  Capybara.threadsafe = true
  Capybara.default_max_wait_time = 60
  Capybara.reuse_server = true

  # Enqueue a job to scrape a URL depending on the site this is set for.
  #
  # @!scope class
  # @param url [String] the url to be scraped
  # @returns [ScrapeJob] the job fired off when this is run
  def self.scrape(url, callback_id = nil, callback_url = Figaro.env.ZENODOTUS_URL, force: false)
    # We want to fail early if the URL is wrong
    # debugger
    model = self.model_for_url(url)
    raise MediaSource::HostError.new(url) if model.nil?

    if Figaro.env.ALLOW_FORCE == "true" && force == "true"
      self.scrape!(url, callback_id, callback_url)
    else
      ScrapeJob.perform_later(url, callback_id, callback_url)
    end
  end

  # Scrape a URL depending on the site this is set for.
  #
  # @!scope class
  # @param url [String] the url to be scraped
  # @returns [Object] the scraped object returned from the respective gem.
  def self.scrape!(url, callback_id, callback_url)
    scrape = Scrape.create!({
      url: url,
      callback_url: callback_url,
      callback_id: callback_id,
    })

    model = self.model_for_url(url)
    object = model.extract(scrape)

    object
  end

  # Takes a screenshot of the page at +url+ and returns the filepath to the image
  # Waits to take screenshot until the element denoted by +indicator_element_id+ has loaded
  # @param url [String]
  # @param indicator_element_id [String] The id of of an element Capybara should wait on to load before screenshotting
  # @return [String] filepath to the screenshot
  def self.take_screenshot(url: @url, indicator_element_id: "")
    session = Capybara::Session.new(:firefox_hypatia)
    session.visit(url)
    begin
      session.find_by_id(indicator_element_id) # Block until page content loadsrescue
    rescue Capybara::ElementNotFound
    end
    screenshot_path = session.save_screenshot("/tmp/#{SecureRandom.uuid}.png")
    session.quit
    screenshot_path
  end

  def self.create_aws_key_functions_for_posts(posts)
    posts.map do |post|
      # First, we add two functions to whatever class the result is.
      # These are implementation details, so we don't want to add them to Zorki or Forki
      # These will allow us to save the AWS keys for later
      post.instance_variable_set("@aws_image_keys", nil)
      post.instance_variable_set("@aws_video_key", nil)
      post.instance_variable_set("@aws_video_preview_key", nil)
      post.instance_variable_set("@aws_screenshot_key", nil)

      post.define_singleton_method(:aws_image_keys) do
        instance_variable_get("@aws_image_keys")
      end

      post.define_singleton_method(:aws_video_key) do
        instance_variable_get("@aws_video_key")
      end

      post.define_singleton_method(:aws_video_preview_key) do
        instance_variable_get("@aws_video_preview_key")
      end

      post.define_singleton_method(:aws_screenshot_key) do
        instance_variable_get("@aws_screenshot_key")
      end

      post
    end
  end

  # Check if +url+ has a host name the same as indicated by the +@@valid_host+ variable in a
  #   subclass.
  #
  # @!scope class
  # @param url [String] the url to be checked for validity
  # @return [Boolean] if the url is valid given the set @@valid_host.
  #   Raises an error if it's invalid.
  def self.check_url(url)
    return true if self.valid_host_name.include?(URI(url).host)
    raise MediaSource::HostError.new(url)
  end

  # A error to indicate the host of a given url does not pass validation
  class HostError < StandardError
    attr_reader :url

    def initialize(url)
      @url = url

      super("No valid scraper found for the url #{url}")
    end
  end

  def self.model_for_url(url)
    # Load all models so we can inspect them
    Zeitwerk::Loader.eager_load_all

    # Get all models conforming to ApplicationRecord, and then check if they implement the magic
    # function.
    models = MediaSource.descendants.select do |model|
      if model.respond_to? :can_handle_url?
        model.can_handle_url?(url)
      end
    end

    # We'll always choose the first one
    models.first
  end

  def s3_transfer_enabled?
    Figaro.env.AWS_REGION.present?
  end
end
