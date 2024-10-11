class ScraperController < ApplicationController
  before_action :verify_auth_key, except: [:heartbeat]

  def heartbeat
    render json: { status: "OK" }
  end

  def scrape
    url = params["url"]
    callback_id = params["callback_id"]
    force = params["force"]

    render json: { error: "Url not given" }, status: 400 and return if url.nil?

    begin
      retry_count ||= 0
      results = MediaSource.scrape(url, callback_id, force: force)
    rescue MediaSource::HostError => e
      logger.error({ error: "MediaSource::HostError encountered while scraping", url: url, count: retry_count += 1 }.to_json)
      render json: e.to_response_structure, status: 400
      return
    rescue Net::ReadTimeout => error
      logger.error({ error: "Net::ReadTimeout encountered while scraping", url: url, count: retry_count += 1 }.to_json)
      sleep(30)
      if retry_count > 4
        logger.error({ error: "Net::ReadTimeout encountered while scraping", url: url, count: retry_count }.to_json)
        render json: "Net::ReadTimeout: #{error.message}", status: 400
        return
      end

      retry
    rescue StandardError => e
      render json: { error: e.message }, status: 400
      return
    end

    if params["force"] == "true" && Figaro.env.ALLOW_FORCE == "true"
      params = { scrape_id: callback_id, scrape_result: PostBlueprint.render(results) }
      render json: params.to_json and return
    end

    render json: { success: true }
  end
end
