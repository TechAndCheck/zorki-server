class InstagramMediaSource < MediaSource
  attr_reader(:url)

  # A string to indicate what type of scraper this model is for
  #
  # @return [String] the canonical name for the type this scraper handles
  def self.model_type
    "instagram"
  end

  # Limit all urls to the host below
  #
  # @return [String] or [Array] of [String] of valid host names
  def self.valid_host_name
    ["www.instagram.com", "instagram.com"]
  end

  # Capture a screenshot of the given url
  #
  # @!scope class
  # @params url [String] the url of the page to be collected for archiving
  # @params save_screenshot [Boolean] whether to save the screenshot image (mostly for testing).
  #   Default: false
  # @returns [String or nil] the path of the screenshot if the screenshot was saved
  def self.extract(scrape, save_screenshot = false)
    object = self.new(scrape.url)
    object.retrieve_instagram_post
  rescue StandardError => error
    error_message = "*Zorki Error 📸:*\n`#{error.class.name}`\n> #{error.message}\n*URL Submitted:* #{scrape.url}"
    self.send_message_to_slack(error_message)
    raise
  end

  # Initialize the object and capture the screenshot automatically.
  #
  # @params url [String] the url of the page to be collected for archiving
  # @returns [Sting or nil] the path of the screenshot if the screenshot was saved
  def initialize(url)
    # Verify that the url has the proper host for this source. (@valid_host is set at the top of
    # this class)
    InstagramMediaSource.check_url(url)
    InstagramMediaSource.validate_instagram_post_url(url)

    @url = url
  end

  # Scrape the page using the Zorki gem and get an object
  #
  # @!visibility private
  # @params url [String] a url to grab data for
  # @return [Zorki::Post]
  def retrieve_instagram_post
    id = InstagramMediaSource.extract_instagram_id_from_url(@url)

    # Zorki is a little flaky now, so this is a retry
    retry_count = 0

    begin
      Zorki::Post.lookup(id)
    rescue Selenium::WebDriver::Error::WebDriverError => e
      retry_count += 1
      raise e if retry_count > 5
    end
  end

  def self.can_handle_url?(url)
    InstagramMediaSource.send(:validate_instagram_post_url, url)
  rescue InstagramMediaSource::InvalidInstagramPostUrlError
    false
  end

private

  # Validate that the url is a direct link to a post, poorly
  #
  # @note this assumes a valid url or else it'll always (usually, maybe, whatever) fail
  #
  # @!scope class
  # @!visibility private
  # @params url [String] a url to check if it's a valid Instagram post url
  # @return [Boolean] if the string validates or not
  def self.validate_instagram_post_url(url)
    return true if /instagram.com\/((p)|(reel)|(tv))\/[\w]+/.match?(url)
    raise InvalidInstagramPostUrlError, "Instagram url #{url} does not have the standard url format"
  end

  # Grab the ID from the end of an Instagram URL
  #
  # @note this assumes a valid url or else it'll return weird stuff
  # @!scope class
  # @!visibility private
  # @params url [String] a url to extract an id from
  # @return [String] the id from the url or [Nil]
  def self.extract_instagram_id_from_url(url)
    uri = URI(url)
    splits = uri.path.split("/")
    raise InstagramMediaSource::InvalidInstagramPostUrlError if splits.empty?
    splits[2]
  end
end

# A class to indicate that a post url passed in is invalid
class InstagramMediaSource::InvalidInstagramPostUrlError < StandardError; end
