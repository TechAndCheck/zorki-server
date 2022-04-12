class ScrapeJob < ApplicationJob
  queue_as :default

  def perform(url, callback_id = nil, callback_url = nil)
    # If there's no callback id or the callback url isn't set, then ignore this
    # Otherwise, send it back to the source
    return if callback_id.blank? || (Figaro.env.ZENODOTUS_URL.blank? && callback_url.blank?)

    results = MediaSource.scrape!(url, callback_id, callback_url)
    params = { scrape_id: callback_id, scrape_result: PostBlueprint.render(results) }

    print "\nFinished scraping #{url}\n"

    print "\n********************\n"
    print "Sending callback to #{callback_url}\n"
    print "params: #{params.keys}"
    print "\n********************\n"

    Typhoeus.post("#{callback_url}/archive/scrape_result_callback",
        headers: { "Content-Type": "application/json" },
        body: params.to_json)
  end
end
