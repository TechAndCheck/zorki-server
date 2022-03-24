class ScrapeJob < ApplicationJob
  queue_as :default

  def perform(url, callback_id = nil, callback_url = nil)
    # If there's no callback id or the callback url isn't set, then ignore this
    # Otherwise, send it back to the source
    return if callback_id.blank? || (Figaro.env.ZENODOTUS_URL.blank? && callback_url.blank?)

    results = MediaSource.scrape!(url, callback_id, callback_url)

    print "\nFinished scraping #{url}\n"

    print "\n********************\n"
    print "Sending callback to #{callback_url}"
    print "\n********************\n"
    Typhoeus.post("#{callback_url}/scrape/callback.json",
        headers: { "Content-Type": "application/json" },
        body: { callback_id: callback_id, scrape_result: PostBlueprint.render(results) }
    )
  end
end
