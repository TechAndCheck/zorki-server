require "test_helper"

class FacebookMediaSourceTest < ActiveSupport::TestCase
  def setup; end

  test "can send error via slack notification" do
    assert_nothing_raised do
      FacebookMediaSource.send_message_to_slack("Test message for Facebook Media Source")
    end
  end

  test "can send error is there is an error while scraping" do
    assert_raise(FacebookMediaSource::InvalidFacebookPostUrlError) do
      FacebookMediaSource.extract(Scrape.create({ url: "https://www.example.com" }))
    end
  end

  test "can extract post without an error being posted to Slack" do
    assert_nothing_raised do
      post = FacebookMediaSource.extract(Scrape.create({ url: "https://www.facebook.com/photo/?fbid=10161587852468065&set=a.10150148489178065" }))
      assert_not_nil(post)
    end
  end
end
