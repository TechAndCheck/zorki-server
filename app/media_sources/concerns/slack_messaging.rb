require "active_support/concern"

module SlackMessaging
  extend ActiveSupport::Concern
  included do
    def self.slack_web_client
      @@slack_web_client ||= Slack::Web::Client.new
    end

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

    def self.send_error_message_to_slack(error_message, error)
      block_payload = [
        {
          type: "header",
          text: {
            type: "plain_text",
            text: "Hypatia Error"
          }
        },
        {
          type: "section",
          text: {
            type: "mrkdwn",
            text: "*Message* ```#{error.message}```"
          }
        },
        {
          type: "section",
          text: {
            type: "mrkdwn",
            text: "*Backtrac exceprt* ```#{error.backtrace[0..3].join("\n\n")}```"
          }
        }
      ].to_json

      error_file = Tempfile.new
      error_file << error.full_message
      error_file.flush
      # compress error to file and upload as well
      # debugger
      self.slack_web_client.chat_postMessage(channel: ENV["SLACK_ERROR_CHANNEL_NAME"], blocks: block_payload,)
      self.send_file(error_file.path, "Error Full Message")
    ensure
      error_file.close
      error_file.unlink
    end

    def self.send_file(file_name, initial_comment = nil)
      Typhoeus.post("https://slack.com/api/files.upload",
        headers: { "Content-Type": "multipart/form-data",
                   "Authorization": "Bearer #{ENV["SLACK_ERROR_API_TOKEN"]}" },
        body: {
          file: File.open(file_name, "r"),
          initial_comment: initial_comment,
          channels: ENV["SLACK_ERROR_CHANNEL_NAME"] })
    end
  end
end
