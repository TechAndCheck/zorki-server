class Scrape < ApplicationRecord
  enum status: {
      not_started: "not_started", completed: "completed", errored: "error"
    }, _prefix: true

  before_validation :set_type
  before_create :ensure_callback_url

  # We can't do this in Postgres so we verify it here
  validates :scrape_type, presence: true

private

  def ensure_callback_url
    self.callback_url = Figaro.env.ZENODOTUS_URL if self.callback_url.nil?
    raise "No callback url specific in configuration or passed in request" if self.callback_url.blank?
  end

  def set_type
    return unless self.scrape_type.nil?

    model = MediaSource.model_for_url(self.url)
    raise MediaSource::HostError.new(self.url) if model.nil?
    self.scrape_type = model.model_type
  end
end
