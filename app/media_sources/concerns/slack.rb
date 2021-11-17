require "active_support/concern"

module Slack
  extend ActiveSupport::Concern
  included do
    def self.send_message_to_slack(message)
      # Check if the environment variable is set, if not, bail out
      return if Figaro.env.SLACK_ERROR_WEBHOOK_URL.nil?

      request = Typhoeus::Request.new(
        Figaro.env.SLACK_ERROR_WEBHOOK_URL,
        method: :post,
        body: { text: message }.to_json,
        headers: { "Content-Type": "application/json" }
      )

      request.run
    end
  end
end

# curl -X POST -H 'Content-type: application/json' --data '{"text":"Hello, World!"}' https://hooks.slack.com/services/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
