require "test_helper"

class YoutubeMediaSourceTest < ActiveSupport::TestCase
  def setup; end

  test "can send error via slack notification" do
    assert_nothing_raised do
      YoutubeMediaSource.send_message_to_slack("Test message for Youtube Media Source")
    end
  end

  test "can send error is there is an error while scraping" do
    assert_raise(MediaSource::HostError) do
      YoutubeMediaSource.extract(Scrape.create({ url: "https://www.example.com" }))
    end
  end

  test "can extract video without an error being posted to Slack" do
    assert_nothing_raised do
      video = YoutubeMediaSource.extract(Scrape.create({ url: "https://www.youtube.com/watch?v=Df7UtQTFUMQ" })) # short video = quick test
      assert_not_nil(video)
    end
  end

  test "extracted video uploaded to S3" do
    posts = YoutubeMediaSource.extract(Scrape.create({ url: "https://www.youtube.com/watch?v=Df7UtQTFUMQ" }))
    assert_not_nil(posts)

    posts.each { |post| assert_not_nil(post.aws_video_key) }
  end

  test "extracted video is not uploaded to S3 if AWS_REGION isn't set" do
    modify_environment_variable("AWS_REGION", nil) do
      posts = YoutubeMediaSource.extract(Scrape.create({ url: "https://www.youtube.com/watch?v=Df7UtQTFUMQ" }))
      assert_not_nil(posts)

      posts.each { |post| assert_nil(post.aws_video_key) }
    end
  end
end
