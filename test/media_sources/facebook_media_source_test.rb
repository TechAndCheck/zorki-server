require "test_helper"

class FacebookMediaSourceTest < ActiveSupport::TestCase
  def setup; end

  def facebook_image_posts
    @@facebook_image_posts ||= FacebookMediaSource.extract(Scrape.create({ url: "https://www.facebook.com/photo/?fbid=10161587852468065&set=a.10150148489178065" }))
  end

  def facebook_video_posts
    @@facebook_video_posts ||= FacebookMediaSource.extract(Scrape.create({ url: "https://www.facebook.com/Meta/videos/264436895517475" }))
  end

  test "can send error via slack notification" do
    assert_nothing_raised do
      FacebookMediaSource.send_message_to_slack("Test message for Facebook Media Source")
    end
  end

  test "can send error is there is an error while scraping" do
    assert_raise(MediaSource::HostError) do
      FacebookMediaSource.extract(Scrape.create({ url: "https://www.example.com" }))
    end
  end

  test "can extract post without an error being posted to Slack" do
    assert_nothing_raised do
      post = FacebookMediaSource.extract(Scrape.create({ url: "https://www.facebook.com/photo/?fbid=10161587852468065&set=a.10150148489178065" }))
      assert_not_nil(post)
    end
  end

  test "extracted video has screenshot" do
    assert_not_nil @@facebook_video_posts.first.screenshot_file
  end

  test "extracted post has images and videos uploaded to S3" do
    skip unless ENV["AWS_REGION"].present?

    posts = facebook_image_posts
    assert_not_nil(posts)

    posts.each { |post| assert_not_nil(post.aws_image_keys) }

    posts = facebook_video_posts
    assert_not_nil(posts)

    posts.each { |post| assert_not_nil(post.aws_video_key) }
    posts.each { |post| assert_not_nil(post.aws_video_preview_key) }
    posts.each { |post| assert_not_nil(post.aws_screenshot_key) }
    posts.each { |post| assert_not_nil(post.user.aws_profile_image_key) }

    json_posts = JSON.parse(PostBlueprint.render(posts))
    json_posts.each { |post| assert_nil post["post"]["image_files"] }
    json_posts.each { |post| assert_nil post["post"]["video_file"] }
    json_posts.each { |post| assert_nil post["post"]["video_file_preview"] }
    json_posts.each { |post| assert_nil post["post"]["screenshot_file"] }
    json_posts.each { |post| assert_not_nil post["post"]["user"]["aws_profile_image_key"] }
  end

  test "extracted post has images and videos are not uploaded to S3 if AWS_REGION isn't set" do
    modify_environment_variable("AWS_REGION", nil) do
      posts = FacebookMediaSource.extract(Scrape.create({ url: "https://www.facebook.com/photo/?fbid=10161587852468065&set=a.10150148489178065" }))
      assert_not_nil(posts)

      posts.each { |post| assert_nil(post.aws_image_keys) }
      posts.each { |post| assert_nil(post.aws_video_key) }
      posts.each { |post| assert_nil(post.aws_video_preview_key) }
      posts.each { |post| assert_nil(post.aws_screenshot_key) }
      posts.each { |post| assert_nil(post.user.aws_profile_image_key) }

      posts = FacebookMediaSource.extract(Scrape.create({ url: "https://www.facebook.com/Meta/videos/264436895517475" }))
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
      json_posts.each { |post| assert_nil post["post"]["user"]["aws_profile_image_key"] }
    end
  end

  test "A reel cross posted from instagram works" do
    posts = FacebookMediaSource.extract(Scrape.create({ url: "https://www.facebook.com/share/r/jh5LX4CNhPXxn83F/" }))
    assert_not_nil(posts)
    assert_predicate posts.count, :positive?
  end

  test "A post with only an image and no text works" do
    posts = FacebookMediaSource.extract(Scrape.create({ url: "https://www.facebook.com/share/p/1AVhvCSLYP/" }))
    assert_not_nil(posts)
    assert_predicate posts.count, :positive?
  end
end
