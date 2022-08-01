require "test_helper"

class TwietterSourceTest < ActiveSupport::TestCase
  def setup; end

  test "can send error via slack notification" do
    assert_nothing_raised do
      TwitterMediaSource.send_message_to_slack("Test message for Youtube Media Source")
    end
  end

  test "can send error is there is an error while scraping" do
    assert_raise(MediaSource::HostError) do
      TwitterMediaSource.extract(Scrape.create({ url: "https://www.example.com" }))
    end
  end

  def test_invalid_tweet_url_raises_error
    assert_raises(MediaSource::HostError) do
      TwitterMediaSource.new(Scrape.create({ url: "https://twitter.com/20" }))
    end
  end

  def test_initializing_returns_blank
    assert_raises(Birdsong::NoTweetFoundError) do
      TwitterMediaSource.extract(Scrape.create({ url: "https://twitter.com/jack/status/1" }))
    end
  end

  test "can extract tweet without an error being posted to Slack" do
    assert_nothing_raised do
      tweet = TwitterMediaSource.extract(Scrape.create({ url: "https://twitter.com/Space4Europe/status/1552221138037755904" })) # short video = quick test
      assert_not_nil(tweet)
    end
  end

  test "extracted image uploaded to S3" do
    skip unless ENV["AWS_REGION"].present?

    tweets = TwitterMediaSource.extract(Scrape.create({ url: "https://twitter.com/Space4Europe/status/1552221138037755904" }))
    assert_not_nil(tweets)

    tweets.each { |tweet| assert_not_nil(tweet.aws_image_keys) }
  end

  test "extracted image is not uploaded to S3 if AWS_REGION isn't set" do
    modify_environment_variable("AWS_REGION", nil) do
      tweet = TwitterMediaSource.extract(Scrape.create({ url: "https://twitter.com/Space4Europe/status/1552221138037755904" }))
      assert_not_nil(tweet)

      assert_nil(tweet.aws_image_keys)
    end
  end

  test "extracted image uploaded to S3 does not have Base64 in JSON version" do
    skip unless ENV["AWS_REGION"].present?

    tweets = TwitterMediaSource.extract(Scrape.create({ url: "https://twitter.com/Space4Europe/status/1552221138037755904" }))
    assert_not_nil(tweets)

    tweets.each { |tweet| assert_not_nil(tweet.aws_image_keys) }

    json_posts = JSON.parse(PostBlueprint.render(tweets))
    json_posts.each { |tweet| assert_nil tweet["post"]["video_file"] }
  end

  test "extracted image is not uploaded to S3 if AWS_REGION isn't set and does have Base64 in JSON version" do
    modify_environment_variable("AWS_REGION", nil) do
      tweet = TwitterMediaSource.extract(Scrape.create({ url: "https://twitter.com/Space4Europe/status/1552221138037755904" }))
      assert_not_nil(tweet)

      assert_nil(tweet.aws_image_keys)

      tweet = JSON.parse(PostBlueprint.render(tweet))
      assert_nil tweet["post"]["image_file_key"]
    end
  end

  test "extracted video uploaded to S3" do
    skip unless ENV["AWS_REGION"].present?

    tweets = TwitterMediaSource.extract(Scrape.create({ url: "https://twitter.com/packers/status/1552345663232417801" }))
    assert_not_nil(tweets)

    tweets.each { |tweet| assert_not_nil(tweet.aws_video_key) }
    tweets.each { |tweet| assert_not_nil(tweet.aws_video_preview_key) }
  end

  test "extracted video is not uploaded to S3 if AWS_REGION isn't set" do
    modify_environment_variable("AWS_REGION", nil) do
      tweet = TwitterMediaSource.extract(Scrape.create({ url: "https://twitter.com/packers/status/1552345663232417801" }))
      assert_not_nil(tweet)

      assert_nil(tweet.aws_video_key)
      assert_nil(tweet.aws_video_preview_key)
    end
  end

  test "extracted video uploaded to S3 does not have Base64 in JSON version" do
    skip unless ENV["AWS_REGION"].present?

    tweets = TwitterMediaSource.extract(Scrape.create({ url: "https://twitter.com/packers/status/1552345663232417801" }))
    assert_not_nil(tweets)

    tweets.each { |tweet| assert_not_nil(tweet.aws_video_key) }
    tweets.each { |tweet| assert_not_nil(tweet.aws_video_preview_key) }

    json_posts = JSON.parse(PostBlueprint.render(tweets))
    json_posts.each { |tweet| assert_nil tweet["post"]["video_file"] }
  end

  test "extracted video is not uploaded to S3 if AWS_REGION isn't set and does have Base64 in JSON version" do
    modify_environment_variable("AWS_REGION", nil) do
      tweet = TwitterMediaSource.extract(Scrape.create({ url: "https://twitter.com/packers/status/1552345663232417801" }))
      assert_not_nil(tweet)

      assert_nil(tweet.aws_video_key)

      tweet = JSON.parse(PostBlueprint.render(tweet))
      assert_nil tweet["post"]["video_file_key"]
    end
  end
end
