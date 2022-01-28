class ScrapeJob < ApplicationJob
  queue_as :default

  def perform(url, callback_id = nil)
    results = MediaSource.scrape!(url)

    # If there's no callback id or the callback url isn't set, then ignore this
    # Otherwise, send it back to the source
    return if callback_id.blank? || Figaro.env.zenodotus_url.blank?

    Typhoeus.post("#{Figaro.env.zenodotus_url}/scrape/callback.json",
        headers: { "Content-Type": "application/json" },
        body: { callback_id: callback_id, scrape_result: PostBlueprint.render(results) }
    )
  end
end
