require "test_helper"

class ScraperControllerTest < ActionDispatch::IntegrationTest
  test "scraping without a url returns a 404" do
    get "/scrape.json", headers: { "Content-type" => "application/json" }, params: { }
    assert_response 400
  end

  test "scraping without an instagram url returns a 404" do
    get "/scrape.json", headers: { "Content-type" => "application/json" }, params: { url: "https://twitter.com/home" }
    assert_response 400
  end

  test "scraping an image works" do
    get "/scrape.json", headers: { "Content-type" => "application/json" }, params: { url: "https://www.instagram.com/p/CS7npabI8IN/?utm_source=ig_web_copy_link" }
    assert_response 200
  end

  test "scraping a video works" do
    get "/scrape.json", headers: { "Content-type" => "application/json" }, params: { url: "https://www.instagram.com/p/CS17kK3n5-J/" }
    assert_response 200
  end
end
