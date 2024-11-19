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

  test "something else" do
    assert_nothing_raised do
      job = ScrapeJob.new("https://www.instagram.com/p/Czblz-nNx-B/", "123")
      job.perform_now
    end
  end

  test "tiktok i guess" do
    assert_nothing_raised do
      job = ScrapeJob.new("https://www.tiktok.com/@guess/video/7091753416032128299")
      job.perform_now
    end
  end

  test "twitter properly retries" do
    assert_enqueued_jobs 1 do
      ScrapeJob.perform_now("https://x.com/izzaag/status/1853913259889606875")
    end
  end

  test "wait time works" do
    assert_equal 0, ScrapeJob.get_correct_period_of_wait_time("https://www.instagram.com/p/Czblz-nNx-B/")
    assert_not_nil Setting.last_scrape_time[:instagram]
    assert_predicate ScrapeJob.get_correct_period_of_wait_time("https://www.instagram.com/p/Czblz-nNx-B/"), :positive?
  end
end
