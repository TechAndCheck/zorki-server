class ScraperController < ApplicationController
  def scrape
    url = "https://www.instagram.com/p/CSsiBchjl14/"
    post = InstagramMediaSource.extract(url)

    
    render json: PostBlueprint.render(post)
	end
end
