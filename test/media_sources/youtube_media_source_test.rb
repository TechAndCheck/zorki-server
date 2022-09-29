require "test_helper"

class YoutubeMediaSourceTest < ActiveSupport::TestCase
  def setup; end

  @@youtube_posts = YoutubeMediaSource.extract(Scrape.create({ url: "https://www.youtube.com/watch?v=Df7UtQTFUMQ" }))

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
      assert_not_nil(@@youtube_posts.first)
    end
  end

  test "extracted video has screenshot" do
    @@youtube_posts.each { |post| assert_not_nil(post.screenshot_file) }
  end

  test "extracted video uploaded to S3" do
    skip unless ENV["AWS_REGION"].present?

    assert_not_nil(@@youtube_posts)

    @@youtube_posts.each { |post| assert_not_nil(post.aws_video_key) }
    @@youtube_posts.each { |post| assert_not_nil(post.aws_video_preview_key) }
    @@youtube_posts.each { |post| assert_not_nil(post.aws_screenshot_key) }
    @@youtube_posts.each { |post| assert_not_nil(post.user.aws_profile_image_key) }
  end

  test "extracted video is not uploaded to S3 if AWS_REGION isn't set" do
    modify_environment_variable("AWS_REGION", nil) do
      posts = YoutubeMediaSource.extract(Scrape.create({ url: "https://www.youtube.com/watch?v=Df7UtQTFUMQ" }))
      assert_not_nil(posts)

      posts.each { |post| assert_nil(post.aws_video_key) }
      posts.each { |post| assert_nil(post.aws_video_preview_key) }
      posts.each { |post| assert_nil(post.aws_screenshot_key) }
      posts.each { |post| assert_nil(post.user.aws_profile_image_key) }
    end
  end

  test "extracted video uploaded to S3 does not have Base64 in JSON version" do
    skip unless ENV["AWS_REGION"].present?

    assert_not_nil(@@youtube_posts)

    @@youtube_posts.each { |post| assert_not_nil(post.aws_video_key) }
    @@youtube_posts.each { |post| assert_not_nil(post.aws_video_preview_key) }
    @@youtube_posts.each { |post| assert_not_nil(post.aws_screenshot_key) }
    @@youtube_posts.each { |post| assert_not_nil(post.user.aws_profile_image_key) }

    json_posts = JSON.parse(PostBlueprint.render(@@youtube_posts))
    json_posts.each { |post| assert_nil post["post"]["image_files"] }
    json_posts.each { |post| assert_nil post["post"]["video_file"] }
    json_posts.each { |post| assert_nil post["post"]["video_file_preview"] }
    json_posts.each { |post| assert_nil post["post"]["screenshot_file"] }
    json_posts.each { |post| assert_nil post["post"]["channel"]["profile_image_file"] }
  end

  test "extracted video is not uploaded to S3 if AWS_REGION isn't set and does have Base64 in JSON version" do
    modify_environment_variable("AWS_REGION", nil) do
      posts = YoutubeMediaSource.extract(Scrape.create({ url: "https://www.youtube.com/watch?v=Df7UtQTFUMQ" }))
      assert_not_nil(posts)

      posts.each { |post| assert_nil(post.aws_image_keys) }
      posts.each { |post| assert_nil(post.aws_video_key) }
      posts.each { |post| assert_nil(post.aws_video_preview_key) }
      posts.each { |post| assert_nil(post.aws_screenshot_key) }
      posts.each { |post| assert_nil(post.user.aws_profile_image_key) }

      json_posts = JSON.parse(PostBlueprint.render(posts))
      json_posts.each { |post| assert_nil post["post"]["aws_image_keys"] }
      json_posts.each { |post| assert_nil post["post"]["aws_video_key"] }
      json_posts.each { |post| assert_nil post["post"]["aws_video_preview_key"] }
      json_posts.each { |post| assert_nil post["post"]["aws_screenshot_key"] }
      json_posts.each { |post| assert_nil post["post"]["channel"]["aws_profile_image_key"] }
    end
  end
end
