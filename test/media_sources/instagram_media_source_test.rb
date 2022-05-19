require "test_helper"

class InstagramMediaSourceTest < ActiveSupport::TestCase
  def setup; end

  test "can send error via slack notification" do
    assert_nothing_raised do
      InstagramMediaSource.send_message_to_slack("Test message for Instagram Media Source")
    end
  end

  test "can send error is there is an error while scraping" do
    assert_raise(MediaSource::HostError) do
      InstagramMediaSource.extract(Scrape.create({ url: "https://www.example.com" }))
    end
  end

  test "can extract post without an error being posted to Slack" do
    assert_nothing_raised do
      # begin
        post = InstagramMediaSource.extract(Scrape.create({ url: "https://www.instagram.com/p/CZu6b08OB0Q/" }))

      # rescue StandardError => e
      #   debugger
      # end

      assert_not_nil(post)
    end
  end
end
