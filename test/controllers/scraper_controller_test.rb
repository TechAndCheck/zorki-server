require "test_helper"

class ScraperControllerTest < ActionDispatch::IntegrationTest
  def setup
    @auth_key = Setting.generate_auth_key
  end

  test "scraping without an auth key returns a 401" do
    get "/scrape.json", headers: { "Content-type" => "application/json" }, params: { }
    assert_response 401
  end

  test "scraping without a wrong auth key returns a 401" do
    get "/scrape.json", headers: { "Content-type" => "application/json" }, params: { auth_key: "123456789" }
    assert_response 401
  end

  test "scraping without a url returns a 404" do
    get "/scrape.json", headers: { "Content-type" => "application/json" }, params: { auth_key: @auth_key }
    assert_response 400
  end

  test "scraping without an instagram url returns a 404" do
    get "/scrape.json", headers: { "Content-type" => "application/json" }, params: { url: "https://twitter.com/home", auth_key: @auth_key }
    assert_response 400
  end

  test "scraping an image works" do
    get "/scrape.json", headers: { "Content-type" => "application/json" }, params: { url: "https://www.instagram.com/p/CS7npabI8IN/?utm_source=ig_web_copy_link", auth_key: @auth_key }
    assert_response 200
  end

  test "scraping a video works" do
    get "/scrape.json", headers: { "Content-type" => "application/json" }, params: { url: "https://www.instagram.com/p/CS17kK3n5-J/", auth_key: @auth_key }
    assert_response 200
  end
end
