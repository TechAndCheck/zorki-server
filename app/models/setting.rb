# RailsSettings Model
class Setting < RailsSettings::Base
  cache_prefix { "v1" }

  field :auth_key, type: :string, default: Figaro.env.PRESET_API_KEY

  def self.generate_auth_key
    charset = Array("A".."Z") + Array("a".."z")
    Setting.auth_key = Array.new(30) { charset.sample }.join
  end
end
