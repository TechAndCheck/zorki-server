class Scrape < ApplicationRecord
  enum status: {
      not_started: "not_started", completed: "completed", errored: "error"
    }, _prefix: true

  before_create :ensure_callback_url

private

  def ensure_callback_url
    self.callback_url = Figaro.env.ZENODOTUS_URL if self.callback_url.nil?
    raise "No callback url specific in configuration or passed in request" if callback_url.blank?
  end
end
