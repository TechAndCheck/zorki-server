class Scrape < ApplicationRecord
  enum status: {
      not_started: "not_started", completed: "completed", errored: "error"
    }, _prefix: true

  before_validation :set_type

  # We can't do this in Postgres so we verify it here
  validates :scrape_type, presence: true

private

  def set_type
    return unless self.scrape_type.nil?

    model = MediaSource.model_for_url(self.url)
    raise MediaSource::HostError.new(self.url) if model.nil?
    self.scrape_type = model.model_type
  end
end
