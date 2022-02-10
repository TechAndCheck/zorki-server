class ScraperController < ApplicationController
  before_action :verify_auth_key

  def scrape
    url = params["url"]
    callback_id = params["callback_id"]

    if Figaro.env.ALLOW_CUSTOM_CALLBACK != "true" && params["callback_url"].blank? == false
      render json: { error: "Callback url not allowed in request" }, status: 400 and return
    end

    callback_url = params["callback_url"].blank? ? Figaro.env.ZENODOTUS_URL : params["callback_url"]

    render json: { error: "Callback url not given or set" }, status: 400 and return if callback_url.nil?
    render json: { error: "Url not given" }, status: 400 and return if url.nil?

    begin
      scrape_job = MediaSource.scrape(url, callback_id)
    rescue MediaSource::HostError
      render json: { error: "Url must be a proper #{ApplicationController.name_for_differentiated_type} url" }, status: 400
      return
    end

    render json: { success: true }
  end
end
