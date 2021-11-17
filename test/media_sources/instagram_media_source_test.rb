require "test_helper"

class InstagramMediaSourceTest < ActiveSupport::TestCase
  def setup; end

  test "can send error via slack notification" do
    InstagramMediaSource.send_message_to_slack("Test message of some sort")
  end

  test "can send error is there is an error while scraping" do
    InstagramMediaSource.extract("https://www.example.com")
  end

  test "can extract post without an error being posted to Slack" do
    InstagramMediaSource.extract("https://www.instagram.com/p/CS17kK3n5-J/")
  end
end
