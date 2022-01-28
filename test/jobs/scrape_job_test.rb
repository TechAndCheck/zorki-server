require "test_helper"

class ScrapeJobTest < ActiveJob::TestCase
  include ActionCable::TestHelper

  test "a scrape job does proper scraping" do
    job = ScrapeJob.new("https://www.instagram.com/p/CS17kK3n5-J")
    job.perform_now
  end
end
