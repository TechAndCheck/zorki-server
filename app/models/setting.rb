# RailsSettings Model
class Setting < RailsSettings::Base
  cache_prefix { "v1" }

  field :auth_key, type: :string, default: Figaro.env.PRESET_API_KEY
  field :last_scrape_time, type: Hash, default: {
    facebook: nil,
    instagram: nil,
    twitter: nil,
    tiktok: nil,
    youtube: nil
  }
  field :scrape_wait_time_range, readonly: true, type: Hash, default: {
    facebook: 1.0...5.0,
    instagram: 0.5...2.0,
    twitter: 0...0,
    tiktok: 0...0,
    youtube: 0...0
  }


  def self.generate_auth_key
    charset = Array("A".."Z") + Array("a".."z")
    Setting.auth_key = Array.new(30) { charset.sample }.join
  end
end
