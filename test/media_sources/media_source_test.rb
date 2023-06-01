require "test_helper"

class MediaSourceTest < ActiveSupport::TestCase
	test "Properly handles error in scrape url" do
    # assert_raise(MediaSource::HostError) do
      MediaSource.scrape!("https://www.example.com", "12345")
    # end
	end
end
