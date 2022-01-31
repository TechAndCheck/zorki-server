class ScraperController < ApplicationController
  before_action :verify_auth_key

  def scrape
    url = params["url"]
    callback_id = params["callback_id"]

    if url.nil?
      render json: { error: "Url not given" }, status: 400
      return
    end

    begin
      scrape_job = MediaSource.scrape(url, callback_id)
    rescue MediaSource::HostError
      render json: { error: "Url must be a proper #{ApplicationController.name_for_differentiated_type} url" }, status: 400
      return
    end

    render json: { success: true }
  end
end
