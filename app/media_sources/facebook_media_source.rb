# typed: true

class FacebookMediaSource < MediaSource
  include Forki
  attr_reader(:url)

  # A string to indicate what type of scraper this model is for
  #
  # @return [String] the canonical name for the type this scraper handles
  def self.model_type
    "facebook"
  end

  # Limit all urls to the host below
  #
  # @return [String] or [Array] of [String] of valid host names
  def self.valid_host_name
    ["www.facebook.com", "web.facebook.com"]
  end

  # Capture a screenshot of the given url
  #
  # @!scope class
  # @params url [String] the url of the page to be collected for archiving
  # @params save_screenshot [Boolean] whether to save the screenshot image (mostly for testing).
  #   Default: false
  # @returns [String or nil] the path of the screenshot if the screenshot was saved
  def self.extract(scrape, save_screenshot = false)
    self.validate_facebook_post_url(scrape.url)
    object = self.new(scrape.url)
    object.retrieve_facebook_post
  rescue Forki::ContentUnavailableError => e
    message = "Facebook post #{scrape.url} is unavailable"
    @@logger.error message
    self.send_message_to_slack(message)
    raise e
  end

  # Validate that the url is a direct link to a post, poorly
  #
  # @note this assumes a valid url or else it'll always (usually, maybe, whatever) fail
  #
  # @!scope class
  # @!visibility private
  # @params url [String] a url to check if it's a valid Facebook post url
  # @return [Boolean] if the string validates or not
  def self.validate_facebook_post_url(url)
    self.valid_host_name.each do |host_name|
      return true if /#{host_name}\//.match?(url)
    end

    raise InvalidFacebookPostUrlError, "Facebook url #{url} does not have the standard url format"
  end

  # Initialize the object and capture the screenshot automatically.
  #
  # @params url [String] the url of the page to be collected for archiving
  # @returns [Sting or nil] the path of the screenshot if the screenshot was saved
  def initialize(url)
    # Verify that the url has the proper host for this source. (@valid_host is set at the top of
    # this class)
    FacebookMediaSource.check_url(url)
    @url = url
  end

  # Scrape the page using the Forki gem and get an object
  #
  # @!visibility private
  # @params url [String] a url to grab data for
  # @return [Forki::Post]
  def retrieve_facebook_post
    # Unlike Zorki, Forki expects a full URL
    posts = Forki::Post.lookup(url)

    self.class.create_aws_key_functions_for_posts(posts)

    return posts unless s3_transfer_enabled?

    posts.map do |post|
      @@logger.debug "Beginning uploading of files to S3 bucket #{Figaro.env.AWS_S3_BUCKET_NAME}"

      # Upload user profile picture to s3
      if post.user.profile_image_file.present?
        @@logger.debug "Uploading user profile picture #{post.user.profile_image_file}"
        aws_upload_wrapper = AwsObjectUploadFileWrapper.new(post.user.profile_image_file)
        aws_upload_wrapper.upload_file
        post.user.instance_variable_set("@aws_profile_image_key", aws_upload_wrapper.object.key)
      end

      # Upload post screenshot to s3
      if post.screenshot_file.present?
        @@logger.debug "Uploading post screenshot #{post.screenshot_file}"
        aws_upload_wrapper = AwsObjectUploadFileWrapper.new(post.screenshot_file)
        aws_upload_wrapper.upload_file
        post.instance_variable_set("@aws_screenshot_key", aws_upload_wrapper.object.key)
      end

      # Let's see if it's a video or images, and upload them
      if post.image_file.present?
        @@logger.debug "Uploading image #{post.image_file}"
        aws_upload_wrapper = AwsObjectUploadFileWrapper.new(post.image_file)
        aws_upload_wrapper.upload_file
        post.instance_variable_set("@aws_image_keys", aws_upload_wrapper.object.key)
      end

      if post.video_files.present?
        aws_video_keys = post.video_files.map do |video_file|
          @@logger.debug "Uploading video #{video_file}"
          aws_upload_wrapper = AwsObjectUploadFileWrapper.new(video_file)
          aws_upload_wrapper.upload_file
          aws_upload_wrapper.object.key
        end
        post.instance_variable_set("@aws_video_keys", aws_video_keys)

        aws_video_preview_keys = post.video_preview_image_files.map do |video_preview_image_file|
          @@logger.debug "Uploading video preview #{video_preview_image_file}"
          aws_upload_wrapper = AwsObjectUploadFileWrapper.new(video_preview_image_file)
          aws_upload_wrapper.upload_file
          aws_upload_wrapper.object.key
        end
        post.instance_variable_set("@aws_video_preview_keys", aws_video_preview_keys)
      end

      post
    end
  end

  def self.can_handle_url?(url)
    FacebookMediaSource.send(:validate_facebook_post_url, url)
  rescue FacebookMediaSource::InvalidFacebookPostUrlError
    false
  end
end

# A class to indicate that a post url passed in is invalid
class FacebookMediaSource::InvalidFacebookPostUrlError < StandardError; end
class FacebookMediaSource::ExternalServerError < StandardError; end
