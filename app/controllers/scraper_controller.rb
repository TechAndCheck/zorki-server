class ScraperController < ApplicationController
  before_action :verify_auth_key

  def scrape
    url = params["url"]

    if url.nil?
      render json: { error: "Url not given" }, status: 400
      return
    end

    post = nil
    begin
      case Figaro.env.DIFFERENTIATE_AS
      when "instagram"
        post = InstagramMediaSource.extract(url)
      when "facebook"
        post = FacebookMediaSource.extract(url)
      end
    rescue MediaSource::HostError
      render json: { error: "Url must be a proper #{ApplicationController.name_for_differentiated_type} url" }, status: 400
      return
    end

    render json: PostBlueprint.render(post)
  end
end
