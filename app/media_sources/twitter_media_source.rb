class TwitterMediaSource < MediaSource
  include Birdsong
  attr_reader(:url)

  # A string to indicate what type of scraper this model is for
  #
  # @return [String] the canonical name for the type this scraper handles
  def self.model_type
    "twitter"
  end

  # Limit all urls to the host below
  #
  # @return [String] or [Array] of [String] of valid host names
  def self.valid_host_name
    ["www.twitter.com", "twitter.com"]
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
    object.retrieve_tweet
  rescue StandardError => error
    error_message = "*Birdsong Error 📸:*\n`#{error.class.name}`\n> #{error.message}\n*URL Submitted:* #{scrape.url}"
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
    TwitterMediaSource.check_url(url)
    TwitterMediaSource.validate_tweet_url(url)

    @url = url
  end

  # Call the Twitter API using the Birdsong gem and get an object
  #
  # @!visibility private
  # @params url [String] a url to grab data for
  # @return [Birdsong::Tweet]
  def retrieve_tweet
    id = TwitterMediaSource.extract_tweet_id_from_url(@url)
    tweet = Birdsong::Tweet.lookup(id).first

    # So, because we're not changing Birdsong up we set this here
    tweet.instance_variable_set("@screenshot_file", self.class.take_screenshot(url: @url))
    tweet.define_singleton_method(:screenshot_file) do
      instance_variable_get("@screenshot_file")
    end

    self.class.create_aws_key_functions_for_posts([tweet])

    return tweet unless s3_transfer_enabled?

    # Upload tweet screenshot to s3
    if tweet.screenshot_file.present?
      @@logger.debug "Uploading tweet screenshot #{tweet.screenshot_file}"
      aws_upload_wrapper = AwsObjectUploadFileWrapper.new(tweet.screenshot_file)
      aws_upload_wrapper.upload_file
      tweet.instance_variable_set("@aws_screenshot_key", aws_upload_wrapper.object.key)
    end

    @@logger.debug "Beginning uploading of files to S3 bucket #{Figaro.env.AWS_S3_BUCKET_NAME}"
    # Let's see if it's a video or images, and upload them
    if tweet.image_file_names.present?
      aws_image_keys = tweet.image_file_names.map do |image_file_name|
        @@logger.debug "Uploading image #{image_file_name}"
        aws_upload_wrapper = AwsObjectUploadFileWrapper.new(image_file_name)
        aws_upload_wrapper.upload_file
        aws_upload_wrapper.object.key
      end

      tweet.instance_variable_set("@aws_image_keys", aws_image_keys)
    elsif tweet.video_file_names.present?
      video_file_keys = []
      video_file_preview_keys = []
      tweet.video_file_names.each do |video_file_name|
        video_file_name = video_file_name.first # To fix some structure stuff
        @@logger.debug "Uploading video #{video_file_name[:url]}"
        aws_upload_wrapper = AwsObjectUploadFileWrapper.new(video_file_name[:url])
        aws_upload_wrapper.upload_file
        video_file_keys << aws_upload_wrapper.object.key


        @@logger.debug "Uploading video preview #{video_file_name[:preview_url]}"
        aws_upload_wrapper = AwsObjectUploadFileWrapper.new(video_file_name[:preview_url])
        aws_upload_wrapper.upload_file
        video_file_preview_keys << aws_upload_wrapper.object.key
      end

      tweet.instance_variable_set("@aws_video_key", video_file_keys)
      tweet.instance_variable_set("@aws_video_preview_key", video_file_preview_keys)
    end

    [tweet]
  end

  # Checks if a URL is supported by this scraper
  #
  # @params url [String] a url to check for compatibility on
  # @return [Boolean] whether the url is supported or not
  def self.can_handle_url?(url)
    TwitterMediaSource.send(:validate_tweet_url, url)
  rescue TwitterMediaSource::InvalidTweetUrlError
    false
  end

private

  # Validate that the url is a direct link to a tweet, poorly
  #
  # @note this assumes a valid url or else it'll always (usually, maybe, whatever) fail
  #
  # @!scope class
  # @!visibility private
  # @params url [String] a url to check if it's a valid Twitter tweet url
  # @return [Boolean] if the string validates or not
  def self.validate_tweet_url(url)
    return true if /twitter.com\/[\w]+\/[\w]+\/[0-9]+/.match?(url)
    raise TwitterMediaSource::InvalidTweetUrlError, "Tweet url #{url} does not have the standard url format"
  end

  # Grab the ID from the end of a twitter URL
  #
  # @note this assumes a valid url or else it'll return weird stuff
  # @!scope class
  # @!visibility private
  # @params url [String] a url to extract an id from
  # @return [String] the id from the url or [Nil]
  def self.extract_tweet_id_from_url(url)
    uri = URI(url)
    splits = uri.path.split("/")
    raise TwitterMediaSource::InvalidTweetUrlError if splits.empty?

    splits.last
  end
end

# A class to indicate that a tweet url passed in is invalid
class TwitterMediaSource::InvalidTweetUrlError < StandardError; end
