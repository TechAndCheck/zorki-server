class MediaSource
  include Slack

  # Enqueue a job to scrape a URL depending on the site this is set for.
  #
  # @!scope class
  # @param url [String] the url to be scraped
  # @returns [ScrapeJob] the job fired off when this is run
  def self.scrape(url, callback_id = nil, callback_url = Figaro.env.ZENODOTUS_URL)
    # We want to fail early if the URL is wrong
    case Figaro.env.DIFFERENTIATE_AS
    when "instagram"
      InstagramMediaSource.check_url(url)
    when "facebook"
      FacebookMediaSource.check_url(url)
    end

    ScrapeJob.perform_later(url, callback_id, callback_url)
    # ScrapeJob.perform_now(url, callback_id)
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

    case Figaro.env.DIFFERENTIATE_AS
    when "instagram"
      InstagramMediaSource.extract(scrape)
    when "facebook"
      FacebookMediaSource.extract(scrape)
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

    raise MediaSource::HostError.new(url, self)
  end

  # A error to indicate the host of a given url does not pass validation
  class HostError < StandardError
    attr_reader :url
    attr_reader :class

    def initialize(url, clazz)
      @url = url
      @class = clazz

      super("Invalid URL passed to #{@class.name}, must have host #{@class.valid_host_name}, given #{URI(url).host}")
    end
  end
end
