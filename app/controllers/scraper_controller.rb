class ScraperController < ApplicationController
  def scrape
    url = "https://www.instagram.com/p/CS7Jd5LFaeK/?utm_source=ig_web_copy_link"
    post = InstagramMediaSource.extract(url)

    images = post.first.image_file_names.map do |file_name|
      file = File.open(file_name).read
      Base64.encode64(file)
    end

    render json: PostBlueprint.render(post)
	end
end
