class MediaSource
  include Slack

  # Enqueue a job to scrape a URL depending on the site this is set for.
  #
  # @!scope class
  # @param url [String] the url to be scraped
  # @returns [ScrapeJob] the job fired off when this is run
  def self.scrape(url, callback_id = nil, callback_url = Figaro.env.ZENODOTUS_URL, force: false)
    # We want to fail early if the URL is wrong
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
    # object = nil
    # case Figaro.env.DIFFERENTIATE_AS
    # when "instagram"
    #   object = InstagramMediaSource.extract(scrape)
    # when "facebook"
    #   object = FacebookMediaSource.extract(scrape)
    # end

    object
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
end
