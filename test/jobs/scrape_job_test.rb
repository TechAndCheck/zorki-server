require "test_helper"

class ScrapeJobTest < ActiveJob::TestCase
  include ActionCable::TestHelper

  test "a scrape job does proper scraping" do
    assert_nothing_raised do
      job = ScrapeJob.new("https://www.instagram.com/p/CS17kK3n5-J", "123", "https://www.example.com")
      job.perform_now
    end
  end
end
