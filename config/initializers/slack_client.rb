return if Figaro.env.SLACK_ERROR_API_TOKEN.nil?

Slack.configure do |config|
  config.token = ENV["SLACK_ERROR_API_TOKEN"]
end