class ScraperController < ApplicationController
  before_action :verify_auth_key

  def scrape
    url = params["url"]

    if url.nil?
      render json: { error: "Url not given" }, status: 400
      return
    end

    begin
      post = InstagramMediaSource.extract(url)
    rescue MediaSource::HostError
      render json: { error: "Url must be a proper #{self.name_for_differentiated_type} url" }, status: 400
      return
    end

    render json: PostBlueprint.render(post)
  end
end
