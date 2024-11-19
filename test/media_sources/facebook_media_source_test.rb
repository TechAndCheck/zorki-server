require "test_helper"

# rubocop:disable Metrics/ClassLength
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
    assert_not_nil facebook_video_posts.first.screenshot_file
  end

  test "extracted post has images and videos uploaded to S3" do
    skip unless ENV["AWS_REGION"].present?

    posts = facebook_image_posts
    assert_not_nil(posts)

    posts.each { |post| assert_not_nil(post.aws_image_keys) }

    posts = facebook_video_posts
    assert_not_nil(posts)

    posts.each do |post|
      assert_not_nil(post.aws_video_key)
      begin
        AwsObjectUploadFileWrapper.download_file(post.aws_video_key, "tmp/forki/video.mp4")
        assert File.exist?("tmp/forki/video.mp4")
        assert File.size("tmp/forki/video.mp4") > 1000
      ensure
        File.delete("tmp/forki/video.mp4") if File.exist?("tmp/forki/video.mp4")
      end
    end
    posts.each do |post|
      assert_not_nil(post.aws_video_preview_key)
      begin
        AwsObjectUploadFileWrapper.download_file(post.aws_video_preview_key, "tmp/forki/video_preview.jpg")
        assert File.size("tmp/forki/video_preview.jpg") > 1000
      ensure
        File.delete("tmp/forki/video_preview.jpg") if File.exist?("tmp/forki/video_preview.jpg")
      end
    end
    posts.each do |post|
      assert_not_nil(post.aws_screenshot_key)
      begin
        AwsObjectUploadFileWrapper.download_file(post.aws_screenshot_key, "tmp/forki/aws_screenshot.jpg")
        assert File.exist?("tmp/forki/aws_screenshot.jpg")
        assert File.size("tmp/forki/aws_screenshot.jpg") > 1000
      ensure
        File.delete("tmp/forki/aws_screenshot.jpg") if File.exist?("tmp/forki/aws_screenshot.jpg")
      end
    end
    posts.each do |post|
      assert_not_nil(post.user.aws_profile_image_key)
      begin
        AwsObjectUploadFileWrapper.download_file(post.user.aws_profile_image_key, "tmp/forki/aws_profile_image.jpg")
        assert File.exist?("tmp/forki/aws_profile_image.jpg")
        assert File.size("tmp/forki/aws_profile_image.jpg") > 1000
      ensure
        File.delete("tmp/forki/aws_profile_image.jpg") if File.exist?("tmp/forki/aws_profile_image.jpg")
      end
    end

    json_posts = JSON.parse(PostBlueprint.render(posts))
    json_posts.each { |post| assert_nil post["post"]["image_files"] }
    json_posts.each { |post| assert_nil post["post"]["video_file"] }
    json_posts.each { |post| assert_nil post["post"]["video_file_preview"] }
    json_posts.each { |post| assert_nil post["post"]["screenshot_file"] }
    json_posts.each do |post|
      assert_not_nil post["post"]["user"]["aws_profile_image_key"]
      begin
        AwsObjectUploadFileWrapper.download_file(post["post"]["user"]["aws_profile_image_key"], "tmp/forki/aws_profile_image.jpg")
        assert File.exist?("tmp/forki/aws_profile_image.jpg")
        assert File.size("tmp/forki/aws_profile_image.jpg") > 1000
      ensure
        File.delete("tmp/forki/aws_profile_image.jpg") if File.exist?("tmp/forki/aws_profile_image.jpg")
      end
    end
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

    begin
      AwsObjectUploadFileWrapper.download_file(posts.first.aws_video_key, "tmp/forki/video.mp4")
      assert File.exist?("tmp/forki/video.mp4")
      assert File.size("tmp/forki/video.mp4") > 1000
    ensure
      File.delete("tmp/forki/video.mp4") if File.exist?("tmp/forki/video.mp4")
    end

    begin
      AwsObjectUploadFileWrapper.download_file(posts.first.aws_video_preview_key, "tmp/forki/video_preview.jpg")
      assert File.exist?("tmp/forki/video_preview.jpg")
      assert File.size("tmp/forki/video_preview.jpg") > 1000
    ensure
      File.delete("tmp/forki/video_preview.jpg") if File.exist?("tmp/forki/video_preview.jpg")
    end
  end

  test "A post with only an image and no text works" do
    posts = FacebookMediaSource.extract(Scrape.create({ url: "https://www.facebook.com/photo/?fbid=10162335943605168&set=a.10153570049545168" }))
    assert_not_nil(posts)
    assert_predicate posts.count, :positive?

    assert_predicate posts.first.image_file, :present?
    assert_predicate posts.first.video_file, :nil?
    assert_predicate posts.first.video_preview_image_file, :nil?
  end

  test "A post with only a video and no text works" do
    posts = FacebookMediaSource.extract(Scrape.create({ url: "https://www.facebook.com/100000568872011/videos/2240868886282175" }))
    assert_not_nil(posts)
    assert_predicate posts.count, :positive?

    assert_predicate posts.first.image_file, :blank?
    assert_predicate posts.first.video_file, :present?

    begin
      AwsObjectUploadFileWrapper.download_file(posts.first.aws_video_key, "tmp/forki/video.mp4")
      assert File.exist?("tmp/forki/video.mp4")
      assert File.size("tmp/forki/video.mp4") > 1000
    ensure
      File.delete("tmp/forki/video.mp4") if File.exist?("tmp/forki/video.mp4")
    end

    begin
      AwsObjectUploadFileWrapper.download_file(posts.first.aws_video_preview_key, "tmp/forki/video_preview.jpg")
      assert File.exist?("tmp/forki/video_preview.jpg")
      assert File.size("tmp/forki/video_preview.jpg") > 1000
    ensure
      File.delete("tmp/forki/video_preview.jpg") if File.exist?("tmp/forki/video_preview.jpg")
    end
  end

  test "A post with only text works" do
    posts = FacebookMediaSource.extract(Scrape.create({ url: "https://www.facebook.com/story.php?story_fbid=10161441611340091&id=579090090&rdid=jEHDYhyTILY1wtaM" }))
    assert_not_nil(posts)
    assert_predicate posts.count, :positive?

    assert_predicate posts.first.video_file, :nil?
    assert_predicate posts.first.image_file, :blank?
    assert_predicate posts.first.video_preview_image_file, :nil?
  end

  test "Does a video actually save itself properly" do
    posts = FacebookMediaSource.extract(Scrape.create({ url: "https://www.facebook.com/share/v/g1uQJ98rQp9pSEjw/" }))
    assert_not_nil(posts)
    assert_predicate posts.count, :positive?

    assert_predicate posts.first.image_file, :blank?
    assert_predicate posts.first.video_file, :present?

    begin
      AwsObjectUploadFileWrapper.download_file(posts.first.aws_video_key, "tmp/forki/video.mp4")
      assert File.exist?("tmp/forki/video.mp4")
      assert File.size("tmp/forki/video.mp4") > 1000
    ensure
      File.delete("tmp/forki/video.mp4") if File.exist?("tmp/forki/video.mp4")
    end

    begin
      AwsObjectUploadFileWrapper.download_file(posts.first.aws_video_preview_key, "tmp/forki/video_preview.jpg")
      assert File.exist?("tmp/forki/video_preview.jpg")
      assert File.size("tmp/forki/video_preview.jpg") > 1000
    ensure
      File.delete("tmp/forki/video_preview.jpg") if File.exist?("tmp/forki/video_preview.jpg")
    end
  end

  test "Another broken link with an image" do
    posts = FacebookMediaSource.extract(Scrape.create({ url: "https://www.facebook.com/permalink.php?story_fbid=pfbid04H3ZNFByHS8CLtNFWqUSuUPq5NATXi2N9uNCfjr4mihtfLkorUBQJqd7AnnazLkcl&id=61567717621263" }))
    assert_not_nil(posts)
    assert_predicate posts.count, :positive?

    assert_predicate posts.first.image_file, :present?
    assert_predicate posts.first.video_file, :nil?
    assert_predicate posts.first.video_preview_image_file, :nil?
  end

  test "can handle multiple videos" do
    post = FacebookMediaSource.extract(Scrape.create({ url: "https://www.facebook.com/permalink.php?story_fbid=pfbid02E26psygjdZJ7YEeEhXJkgTpbDdjYZZHNZyezK9iA65PGPwQKT35pHb4GjoVVexGcl&id=100079991325065" }))
    assert_not_nil(post)
  end
end
