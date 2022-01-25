# Since this can be a number of different types of scrapers, this variable determines what sort of
# system we're deploying. The options (as of now) are as follows:
# `instagram`
# `facebook`
Figaro.require_keys("DIFFERENTIATE_AS", "secret_key_base")

case Figaro.env.DIFFERENTIATE_AS
when "instagram"
  Figaro.require_keys("INSTAGRAM_USER_NAME", "INSTAGRAM_PASSWORD")
when "facebook"
  Figaro.require_keys("FACEBOOK_USER_NAME", "FACEBOOK_PASSWORD")
else
  raise "Invalid Differentiation Type: \"#{Figaro.env.DIFFERENTIATE_AS}\" must be of a valid type. Look at `/config/initializers/figaro.rb` for options."
end

# Other optional environment variables:
#
# SLACK_ERROR_WEBHOOK_URL
# ---
# When set this will enable the reporting of scraping errors to a Slack channel.
# To set up you can create an "Incoming Webhook" at https://api.slack.com/apps
# and put the url in this environment variable.
