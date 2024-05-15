require "sidekiq/api"

class ScrapeJob < ApplicationJob
  sidekiq_options retry: 10
  queue_as :default

  retry_on Birdsong::RateLimitExceeded, wait: 400.seconds, jitter: 0.30, attempts: 10

  sidekiq_retries_exhausted do |message, error|
    puts "Exhausted retries trying to scrape url #{message['arguments'].first}. Error: #{error}"
    Typhoeus.post("#{Figaro.env.GRIGORI_CALLBACK_URL}/archive/scrape_result_callback",
                  headers: { "Content-Type": "application/json" },
                  body: { scrape_id: callback_id, scrape_result: "[]" })
  end

  def perform(url, callback_id = nil)
    # If there's no callback id or the callback url isn't set, then ignore this
    # Otherwise, send it back to the source

    # TODO: Allow custom callbacks

    results = MediaSource.scrape!(url, callback_id)

    print "\nFinished scraping #{url}\n"
    print "\n********************\n"
    print "Sending callback to #{Figaro.env.GRIGORI_CALLBACK_URL}\n"
    print "\n********************\n"

    raise "Nil returned from scraping for #{url}" if results.nil?
    CommsManager.send_scrape_status_update(ENV["VM_NAME"], 203, { url: url, scrape_id: callback_id, result: PostBlueprint.render(results) })

    # params = { scrape_id: callback_id, scrape_result: PostBlueprint.render(results) }

    # Typhoeus.post("#{Figaro.env.GRIGORI_CALLBACK_URL}/archive/scrape_result_callback",
    #     headers: { "Content-Type": "application/json" },
    #     body: params.to_json)
  rescue Zorki::RetryableError, Forki::RetryableError, YoutubeArchiver::RetryableError => e
    # We don't want errors to ruin everything so we'll catch everything
    e.set_backtrace([])
    raise e
  rescue Zorki::ContentUnavailableError, Forki::ContentUnavailableError, YoutubeArchiver::VideoNotFoundError,
          YoutubeArchiver::ChannelNotFoundError, Birdsong::NoTweetFoundError, Morris::ContentUnavailableError => e
    # This means the content has been taken down before we could get to it.
    # Here we do a callback but with a notification the content is removed

    CommsManager.send_scrape_status_update(ENV["VM_NAME"], 303, { url: url, scrape_id: callback_id })

    print "\nPost removed at: #{url}\n"

    Honeybadger.notify(e, context: { url: url, status: "removed" })
  rescue MediaSource::HostError => e
    # This means the content can't be scraped, which is not good. However, we don't want to keep retrying
    # so we send an error back to Zenodotus
    CommsManager.send_scrape_status_update(ENV["VM_NAME"], 302, { url: url, scrape_id: callback_id })

    print "\nPost parsing error at: #{url}\n"

    Honeybadger.notify(e, context: { url: url, status: "error" })
  rescue Birdsong::RateLimitExceeded => e
    Honeybadger.notify(e, context: { url: url, status: "rate_limit_exceeded" })
    raise e
  rescue StandardError => e # If we run into an error retries can't fix, don't retry the job
    # We don't want errors to ruin everything so we'll catch everything
    puts "*************************************************************"
    puts "Error During Scraping"
    puts "Type: #{e.class.name}"
    puts "Timestamp: #{Time.now}"
    puts "Status: Unrecoverable"
    puts "URL: #{url}"
    puts "Message: #{e.full_message(highlight: true)}"
    puts "*************************************************************"
    Honeybadger.notify(e, context: { url: url, status: "unknown" })

    CommsManager.send_scrape_status_update(ENV["VM_NAME"], 302, { url: url, scrape_id: callback_id, message: e.full_message(highlight: true) })
  ensure
    # TODO: Only sleep for the services we need to
    # Facebook: Yes
    # Instagram: Yes
    # Twitter: No, uses an API
    # YouTube: No, uses downloader

    # Note: we should really do queues and skip around to prioritize the density, if we ever need it
    media_source_class = MediaSource.model_for_url(url)
    if media_source_class == FacebookMediaSource
      sleep_time = rand(1.0...5.0) * 60 # Facebook is the most careful, so we wait between 1 and 5 minutes
    elsif media_source_class == InstagramMediaSource
      sleep_time = rand(0.5...2.0) * 60 # Instagram seems less cruel so we can do between half a minute and 2
    end

    # If we're not waiting just go ahead, otherwise, sleep
    unless sleep_time.nil?
      puts "Sleeping #{sleep_time} seconds to hopefully prevent scraping bots from noticing us."
      sleep(sleep_time)
    end
  end
end
