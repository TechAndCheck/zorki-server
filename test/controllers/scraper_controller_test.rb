# rubocop:disable Metrics/ClassLength

require "test_helper"

class ScraperControllerTest < ActionDispatch::IntegrationTest
  def setup
    @auth_key = Setting.generate_auth_key
  end

  test "can check heartbeat" do
    get "/heartbeat"

    assert_response 200
  end

  test "scraping without an auth key returns a 401" do
    post "/scrape.json", headers: { "Content-type" => "application/json" }, body: {}
    assert_response 401
  end

  test "scraping without a wrong auth key returns a 401" do
    post "/scrape.json", headers: { "Content-type" => "application/json" }, params: { auth_key: "123456789" }
    assert_response 401
  end

  test "scraping without a url returns a 400" do
    post "/scrape.json", headers: { "Content-type" => "application/json" }, params: { auth_key: @auth_key }
    assert_response 400
  end

  test "scraping without an instagram url returns a 400" do
    post "/scrape.json", headers: { "Content-type" => "application/json" }, params: { url: "https://twitter.com/home", auth_key: @auth_key }
    assert_response 400
  end

  test "scraping an instagram image works" do
    post "/scrape.json", headers: { "Content-type" => "application/json" }, params: { url: "https://www.instagram.com/p/CS7npabI8IN/?utm_source=ig_web_copy_link", auth_key: @auth_key }
    assert_response 200
  end

  test "scraping an instagram video works" do
    assert_enqueued_jobs(1) do
      post "/scrape.json", headers: { "Content-type" => "application/json" }, params: { url: "https://www.instagram.com/p/Cvco_YJOLRL/", auth_key: @auth_key, as: :json }
      assert_response 200
      assert JSON.parse(@response.body).has_key?("success")
    end
  end

  test "scraping a facebook image works" do
    post "/scrape.json", params: { url: "https://www.facebook.com/photo/?fbid=10161587852468065&set=a.10150148489178065", auth_key: @auth_key }, as: :json
    assert_response 200

    perform_enqueued_jobs
  end

  test "scraping a facebook video works" do
    assert_enqueued_jobs(1) do
      post "/scrape.json", params: { url: "https://www.facebook.com/PlandemicMovie/videos/588866298398729/", auth_key: @auth_key }, as: :json
      assert_response 200
      assert JSON.parse(@response.body).has_key?("success")
    end

    perform_enqueued_jobs
  end

  test "scraping an instagram image with force works" do
    post "/scrape.json", headers: { "Content-type" => "application/json" }, params: { url: "https://www.instagram.com/p/CS7npabI8IN/?utm_source=ig_web_copy_link", auth_key: @auth_key, force: "true" }
    assert_response 200
    assert JSON.parse(JSON.parse(@response.body)["scrape_result"]).first.has_key?("id")
  end

  test "scraping an instagram video with force works" do
    assert_enqueued_jobs(0) do
      post "/scrape.json", headers: { "Content-type" => "application/json" }, params: { url: "https://www.instagram.com/p/CjgHR91Aj8D/", auth_key: @auth_key, as: :json, force: "true" }
      assert_response 200
      assert JSON.parse(JSON.parse(@response.body)["scrape_result"]).first.has_key?("id")
    end
  end

  test "scraping a facebook image with force works" do
    post "/scrape.json", headers: { "Content-type" => "application/json" }, params: { url: "https://www.facebook.com/photo/?fbid=10161587852468065&set=a.10150148489178065", auth_key: @auth_key, force: "true" }
    assert_response 200
    parsed = JSON.parse(JSON.parse(@response.body)["scrape_result"]).first

    assert parsed.has_key?("id")
    assert parsed.has_key?("post")
    assert_not_nil(parsed["post"])
    assert parsed["post"].has_key?("user")
  end

  test "scraping a facebook video with force works" do
    assert_enqueued_jobs(0) do
      post "/scrape.json", headers: { "Content-type" => "application/json" }, params: { url: "https://www.facebook.com/PlandemicMovie/videos/588866298398729/", auth_key: @auth_key, as: :json, force: "true" }
      assert_response 200
      assert JSON.parse(JSON.parse(@response.body)["scrape_result"]).first.has_key?("id")
    end
  end

  test "scraping a facebook link that seems to fail works" do
    perform_enqueued_jobs do
      post "/scrape.json", headers: { "Content-type" => "application/json" }, params: { url: "https://www.facebook.com/mydefiguru/posts/2857725071050020/", auth_key: @auth_key, as: :json, force: "true" }
    end
  end

  test "scraping a youtube video with force works" do
    assert_enqueued_jobs(0) do
      post "/scrape.json", headers: { "Content-type" => "application/json" }, params: { url: "https://www.youtube.com/watch?v=MUaNz9M8fs8", auth_key: @auth_key, as: :json, force: "true" }
      assert_response 200
      assert JSON.parse(JSON.parse(@response.body)["scrape_result"]).first.has_key?("id")
    end
  end

  test "scraping a twitter image works" do
    post "/scrape.json", headers: { "Content-type" => "application/json" }, params: { url: "https://twitter.com/POTUS/status/1562462774969581570?s=20&t=-Dfve5GSFD7EsJDFTJU7GA", auth_key: @auth_key }
    assert_response 200
    assert JSON.parse(@response.body).has_key?("success")
  end

  test "scraping an twitter video works" do
    assert_enqueued_jobs(1) do
      post "/scrape.json", headers: { "Content-type" => "application/json" }, params: { url: "https://twitter.com/bunsenbernerbmd/status/1562110165708550144?s=20&t=-Dfve5GSFD7EsJDFTJU7GA", auth_key: @auth_key, as: :json }
      assert_response 200
      assert JSON.parse(@response.body).has_key?("success")
    end
  end

  test "scraping a twitter image with force works" do
    assert_enqueued_jobs(0) do
      post "/scrape.json", headers: { "Content-type" => "application/json" }, params: { url: "https://twitter.com/POTUS/status/1562462774969581570?s=20&t=-Dfve5GSFD7EsJDFTJU7GA", auth_key: @auth_key, as: :json, force: "true" }
      assert_response 200
      assert JSON.parse(JSON.parse(@response.body)["scrape_result"]).first.has_key?("id")
    end
  end

  test "scraping a twitter video with force works" do
    assert_enqueued_jobs(0) do
      post "/scrape.json", headers: { "Content-type" => "application/json" }, params: { url: "https://twitter.com/bunsenbernerbmd/status/1562110165708550144?s=20&t=-Dfve5GSFD7EsJDFTJU7GA", auth_key: @auth_key, as: :json, force: "true" }
      assert_response 200
      assert JSON.parse(JSON.parse(@response.body)["scrape_result"]).first.has_key?("id")
    end
  end

  test "scraping a tiktok video works" do
    assert_enqueued_jobs(1) do
      post "/scrape.json", headers: { "Content-type" => "application/json" }, params: { url: "https://www.tiktok.com/@guess/video/7091753416032128299", auth_key: @auth_key, as: :json }
      assert_response 200
      json = JSON.parse(@response.body)
      assert json.has_key?("success")
    end
  end

  test "scraping a tiktok video with force works" do
    assert_enqueued_jobs(0) do
      post "/scrape.json", headers: { "Content-type" => "application/json" }, params: { url: "https://www.tiktok.com/@guess/video/7091753416032128299", auth_key: @auth_key, as: :json, force: true }
      assert_response 200
      assert JSON.parse(JSON.parse(@response.body)["scrape_result"]).first.has_key?("id")
    end
  end


  test "submitting multiple jobs works" do
    assert_enqueued_jobs(3) do
      post "/scrape.json", headers: { "Content-type" => "application/json" }, params: { url: "https://www.instagram.com/p/Cvco_YJOLRL/", auth_key: @auth_key, as: :json }
      post "/scrape.json", headers: { "Content-type" => "application/json" }, params: { url: "https://www.instagram.com/p/Cvco_YJOLRL/", auth_key: @auth_key, as: :json }
      post "/scrape.json", headers: { "Content-type" => "application/json" }, params: { url: "https://www.instagram.com/p/Cvco_YJOLRL/", auth_key: @auth_key, as: :json }

      assert_response 200
      assert JSON.parse(@response.body).has_key?("success")
    end
  end

  test "forcing a scrape works and renders a result" do
    assert_enqueued_jobs(0) do
      post "/scrape.json", headers: { "Content-type" => "application/json" }, params: { url: "https://www.instagram.com/p/CjgHR91Aj8D/", auth_key: @auth_key, as: :json, force: "true" }
      assert_response 200
      assert JSON.parse(JSON.parse(@response.body)["scrape_result"]).first.has_key?("id")
    end
  end
end
