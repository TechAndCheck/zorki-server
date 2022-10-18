require "sidekiq/api"

class ScrapeJob < ApplicationJob
  sidekiq_options retry: 10
  queue_as :default

  sidekiq_retries_exhausted do |message, error|
    puts "Exhausted retries trying to scrape url #{message['arguments'].first}. Error: #{error}"
    Typhoeus.post("#{callback_url}/archive/scrape_result_callback",
                  headers: { "Content-Type": "application/json" },
                  body: { scrape_id: callback_id, scrape_result: "[]" })
  end

  def perform(url, callback_id = nil, callback_url = nil)
    # If there's no callback id or the callback url isn't set, then ignore this
    # Otherwise, send it back to the source
    return if callback_id.blank? || (Figaro.env.ZENODOTUS_URL.blank? && callback_url.blank?)

    results = MediaSource.scrape!(url, callback_id, callback_url)

    print "\nFinished scraping #{url}\n"
    print "\n********************\n"
    print "Sending callback to #{callback_url}\n"
    print "\n********************\n"

    params = { scrape_id: callback_id, scrape_result: PostBlueprint.render(results) }

    Typhoeus.post("#{callback_url}/archive/scrape_result_callback",
        headers: { "Content-Type": "application/json" },
        body: params.to_json)
  rescue Zorki::RetryableError, Forki::RetryableError, YoutubeArchiver::RetryableError => e
    # We don't want errors to ruin everything so we'll catch everything
    e.set_backtrace([])
    raise e
  rescue Zorki::ContentUnavailableError, Forki::ContentUnavailableError, YoutubeArchiver::ChannelNotFoundError
    # This means the content has been taken down before we could get to it.
    # Here we do a callback but with a notification the content is removed

    print "\nPost removed at: #{url}\n"
    print "\n********************\n"
    print "Sending callback to #{callback_url}\n"
    print "\n********************\n"

    params = { scrape_id: callback_id, scrape_result: { url: url, status: "removed" } }

    Typhoeus.post("#{callback_url}/archive/scrape_result_callback",
        headers: { "Content-Type": "application/json" },
        body: params.to_json)

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
  ensure
    sleep(rand(1.0...7.0) * 60)
  end
end
