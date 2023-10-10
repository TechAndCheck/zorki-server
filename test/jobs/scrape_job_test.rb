require "test_helper"

class ScrapeJobTest < ActiveJob::TestCase
  include ActionCable::TestHelper

  test "a scrape job does proper scraping" do
    assert_nothing_raised do
      job = ScrapeJob.new("https://www.instagram.com/p/CxeOKRVuOls/", "123")
      job.perform_now
    end
  end

  test "a scrape job doesn't raise an error if a post has been removed" do
    assert_nothing_raised do
      # Note: this url is meaningless
      job = ScrapeJob.new("https://www.instagram.com/p/Cx9Ww4GSPou/", "123")
      job.perform_now
    end

    assert_nothing_raised do
      # Note: this url is removed
      job = ScrapeJob.new("https://www.instagram.com/p/CS17kK3n8", "123")
      job.perform_now
    end
  end
end
