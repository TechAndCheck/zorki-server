require_relative "boot"

require "rails/all"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Hypatia
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 6.1

    # Configuration for the application, engines, and railties goes here.
    #
    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.
    #
    # config.time_zone = "Central Time (US & Canada)"
    # config.eager_load_paths << Rails.root.join("extras")

    config.active_job.queue_adapter = :sidekiq
    config.action_cable.disable_request_forgery_protection = true

    # This is to make sure the AWS uploader (and anything later) is available
    config.eager_load_paths << Rails.root.join("lib/libraries")
    # Note: In Rails 7.1 the following line should work, but for some reason isn't autoloading /lib/libraries
    # This other way will proabably be deprecated at some point so I'm putting the next line here for the future'
    # config.eager_load_paths << Rails.root.join("lib/libraries")

    # if ENV["RAILS_LOG_TO_STDOUT"].present?
    #   logger           = ActiveSupport::Logger.new(STDOUT)
    #   logger.formatter = config.log_formatter
    #   config.logger    = ActiveSupport::TaggedLogging.new(logger)
    # end

    config.logger = Logger.new(STDOUT)

    # if ENV.has_key?("HOST") && ENV["HOST"].blank? == false
    # config.logger.info "Loading #{ENV["HOST"]} as a potential host name..."
    # config.hosts << ENV["HOST"]
    # end

    config.after_initialize do
      CommsManager.send_boot_checkin
    end
  end
end
