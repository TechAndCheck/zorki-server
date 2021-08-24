class MediaSource
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
