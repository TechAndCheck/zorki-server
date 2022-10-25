class ScraperController < ApplicationController
  before_action :verify_auth_key

  def scrape
    url = params["url"]
    callback_id = params["callback_id"]
    force = params["force"]

    render json: { error: "Url not given" }, status: 400 and return if url.nil?

    begin
      retry_count ||= 0
      results = MediaSource.scrape(url, callback_id, force: force)
    rescue MediaSource::HostError => e
      render json: { error: e }, status: 400
      return
    rescue Net::ReadTimeout => error
      print({ error: "Net::ReadTimeout encountered while scraping", url: url, count: retry_count += 1 }.to_json)
      sleep(30)
      raise error if retry_count > 4
      retry
    end

    if params["force"] == "true" && Figaro.env.ALLOW_FORCE == "true"
      params = { scrape_id: callback_id, scrape_result: PostBlueprint.render(results) }
      render json: params.to_json and return
    end

    render json: { success: true }
  end
end
