# rubocop:disable Metrics/ClassLength

require "test_helper"

class ScraperControllerTest < ActionDispatch::IntegrationTest
  def setup
    @auth_key = Setting.generate_auth_key
  end

  test "scraping without an auth key returns a 401" do
    get "/scrape.json", headers: { "Content-type" => "application/json" }, params: {}
    assert_response 401
  end

  test "scraping without a wrong auth key returns a 401" do
    get "/scrape.json", headers: { "Content-type" => "application/json" }, params: { auth_key: "123456789" }
    assert_response 401
  end

  test "scraping without a callback_url or ZENODOTUS_URL when ALLOW_CUSTOM_CALLBACK is true returns a 400" do
    # Remove the fallback url for this test, then reinstate it
    modify_environment_variable("ZENODOTUS_URL", nil) do
      get "/scrape.json", headers: { "Content-type" => "application/json" }, params: { auth_key: @auth_key }
      assert_response 400
    end
  end

  test "scraping with a callback_url without ZENODOTUS_URL when ALLOW_CUSTOM_CALLBACK is true works" do
    # Remove the fallback url for this test, then reinstate it
    assert_enqueued_jobs(1) do
      modify_environment_variable("ZENODOTUS_URL", nil) do
        get "/scrape.json", headers: { "Content-type" => "application/json" }, params: {
          url: "https://www.instagram.com/p/CS7npabI8IN/?utm_source=ig_web_copy_link",
          auth_key: @auth_key,
          callback_url: "https://example.com"
        }
        assert_response 200
      end
    end
  end

  test "scraping without a callback_url with a ZENODOTUS_URL when ALLOW_CUSTOM_CALLBACK is true works" do
    # Remove the fallback url for this test, then reinstate it
    assert_enqueued_jobs(1) do
      get "/scrape.json", headers: { "Content-type" => "application/json" }, params: {
        url: "https://www.instagram.com/p/CS7npabI8IN/?utm_source=ig_web_copy_link",
        auth_key: @auth_key
      }
      assert_response 200
    end
  end

  test "scraping with a callback_url with a ZENODOTUS_URL when ALLOW_CUSTOM_CALLBACK is false fails" do
    # Remove the fallback url for this test, then reinstate it
    assert_enqueued_jobs(0) do
      modify_environment_variable("ALLOW_CUSTOM_CALLBACK", nil) do
        get "/scrape.json", headers: { "Content-type" => "application/json" }, params: {
          url: "https://www.instagram.com/p/CS7npabI8IN/?utm_source=ig_web_copy_link",
          auth_key: @auth_key,
          callback_url: "https://example.com"
        }
        assert_response 400
      end
    end
  end

  test "scraping without a url returns a 400" do
    get "/scrape.json", headers: { "Content-type" => "application/json" }, params: { auth_key: @auth_key }
    assert_response 400
  end

  test "scraping without an instagram url returns a 400" do
    get "/scrape.json", headers: { "Content-type" => "application/json" }, params: { url: "https://twitter.com/home", auth_key: @auth_key }
    assert_response 400
  end

  test "scraping an instagram image works" do
    get "/scrape.json", headers: { "Content-type" => "application/json" }, params: { url: "https://www.instagram.com/p/CS7npabI8IN/?utm_source=ig_web_copy_link", auth_key: @auth_key }
    assert_response 200
  end

  test "scraping an instagram video works" do
    assert_enqueued_jobs(1) do
      get "/scrape.json", headers: { "Content-type" => "application/json" }, params: { url: "https://www.instagram.com/p/CS17kK3n5-J/", auth_key: @auth_key, as: :json }
      assert_response 200
      assert JSON.parse(@response.body).has_key?("success")
    end
  end

  test "scraping a facebook image works" do
    get "/scrape.json", headers: { "Content-type" => "application/json" }, params: { url: "https://www.facebook.com/photo/?fbid=10161587852468065&set=a.10150148489178065", auth_key: @auth_key }
    assert_response 200
  end

  test "scraping a facebook video works" do
    assert_enqueued_jobs(1) do
      get "/scrape.json", headers: { "Content-type" => "application/json" }, params: { url: "https://www.facebook.com/PlandemicMovie/videos/588866298398729/", auth_key: @auth_key, as: :json }
      assert_response 200
      assert JSON.parse(@response.body).has_key?("success")
    end
  end

  test "scraping an instagram image with force works" do
    get "/scrape.json", headers: { "Content-type" => "application/json" }, params: { url: "https://www.instagram.com/p/CS7npabI8IN/?utm_source=ig_web_copy_link", auth_key: @auth_key, force: "true" }
    assert_response 200
    assert JSON.parse(JSON.parse(@response.body)["scrape_result"]).first.has_key?("id")
  end

  test "scraping an instagram video with force works" do
    assert_enqueued_jobs(0) do
      get "/scrape.json", headers: { "Content-type" => "application/json" }, params: { url: "https://www.instagram.com/p/CS17kK3n5-J/", auth_key: @auth_key, as: :json, force: "true" }
      assert_response 200
      assert JSON.parse(JSON.parse(@response.body)["scrape_result"]).first.has_key?("id")
    end
  end

  test "scraping a facebook image with force works" do
    get "/scrape.json", headers: { "Content-type" => "application/json" }, params: { url: "https://www.facebook.com/photo/?fbid=10161587852468065&set=a.10150148489178065", auth_key: @auth_key, force: "true" }
    assert_response 200
    parsed = JSON.parse(JSON.parse(@response.body)["scrape_result"]).first

    assert parsed.has_key?("id")
    assert parsed.has_key?("post")
    assert_not_nil(parsed["post"])
    assert parsed["post"].has_key?("user")
  end

  test "scraping a facebook video with force works" do
    assert_enqueued_jobs(0) do
      get "/scrape.json", headers: { "Content-type" => "application/json" }, params: { url: "https://www.facebook.com/PlandemicMovie/videos/588866298398729/", auth_key: @auth_key, as: :json, force: "true" }
      assert_response 200
      assert JSON.parse(JSON.parse(@response.body)["scrape_result"]).first.has_key?("id")
    end
  end

  test "scraping a youtube video with force works" do
    assert_enqueued_jobs(0) do
      get "/scrape.json", headers: { "Content-type" => "application/json" }, params: { url: "https://www.youtube.com/watch?v=MUaNz9M8fs8", auth_key: @auth_key, as: :json, force: "true" }
      assert_response 200
      assert JSON.parse(JSON.parse(@response.body)["scrape_result"]).first.has_key?("id")
    end
  end

  test "scraping a twitter image works" do
    get "/scrape.json", headers: { "Content-type" => "application/json" }, params: { url: "https://twitter.com/POTUS/status/1562462774969581570?s=20&t=-Dfve5GSFD7EsJDFTJU7GA", auth_key: @auth_key }
    assert_response 200
    assert JSON.parse(@response.body).has_key?("success")
  end

  test "scraping an twitter video works" do
    assert_enqueued_jobs(1) do
      get "/scrape.json", headers: { "Content-type" => "application/json" }, params: { url: "https://twitter.com/bunsenbernerbmd/status/1562110165708550144?s=20&t=-Dfve5GSFD7EsJDFTJU7GA", auth_key: @auth_key, as: :json }
      assert_response 200
      assert JSON.parse(@response.body).has_key?("success")
    end
  end

  test "scraping a twitter image with force works" do
    assert_enqueued_jobs(0) do
      get "/scrape.json", headers: { "Content-type" => "application/json" }, params: { url: "https://twitter.com/POTUS/status/1562462774969581570?s=20&t=-Dfve5GSFD7EsJDFTJU7GA", auth_key: @auth_key, as: :json, force: "true" }
      assert_response 200
      assert JSON.parse(JSON.parse(@response.body)["scrape_result"]).first.has_key?("id")
    end
  end

  test "scraping a twitter video with force works" do
    assert_enqueued_jobs(0) do
      get "/scrape.json", headers: { "Content-type" => "application/json" }, params: { url: "https://twitter.com/bunsenbernerbmd/status/1562110165708550144?s=20&t=-Dfve5GSFD7EsJDFTJU7GA", auth_key: @auth_key, as: :json, force: "true" }
      assert_response 200
      assert JSON.parse(JSON.parse(@response.body)["scrape_result"]).first.has_key?("id")
    end
  end


  test "submitting multiple jobs works" do
    assert_enqueued_jobs(3) do
      get "/scrape.json", headers: { "Content-type" => "application/json" }, params: { url: "https://www.instagram.com/p/CS17kK3n5-J/", auth_key: @auth_key, as: :json }
      get "/scrape.json", headers: { "Content-type" => "application/json" }, params: { url: "https://www.instagram.com/p/CS17kK3n5-J/", auth_key: @auth_key, as: :json }
      get "/scrape.json", headers: { "Content-type" => "application/json" }, params: { url: "https://www.instagram.com/p/CS17kK3n5-J/", auth_key: @auth_key, as: :json }

      assert_response 200
      assert JSON.parse(@response.body).has_key?("success")
    end
  end

  test "forcing a scrape works and renders a result" do
    assert_enqueued_jobs(0) do
      get "/scrape.json", headers: { "Content-type" => "application/json" }, params: { url: "https://www.instagram.com/p/CS17kK3n5-J/", auth_key: @auth_key, as: :json, force: "true" }
      assert_response 200
      assert JSON.parse(JSON.parse(@response.body)["scrape_result"]).first.has_key?("id")
    end
  end
end
