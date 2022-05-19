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
    params = { scrape_id: callback_id, scrape_result: PostBlueprint.render(results) }

    print "\nFinished scraping #{url}\n"
    print "\n********************\n"
    print "Sending callback to #{callback_url}\n"
    print "\n********************\n"

    Typhoeus.post("#{callback_url}/archive/scrape_result_callback",
        headers: { "Content-Type": "application/json" },
        body: params.to_json)
  rescue Zorki::RetryableError, Forki::RetryableError, YoutubeArchiver::RetryableError => e
    e.set_backtrace([])
    raise e
  rescue StandardError => e # If we run into an error retries can't fix, don't retry the job
    puts "#{e} for url #{url}"
  end
end
