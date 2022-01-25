class ApplicationController < ActionController::Base
private

  def verify_auth_key
    auth_key = params["auth_key"]

    if auth_key.nil? || auth_key != Setting.auth_key
      render json: { error: "Unauthroized key" }, status: 401
      return false
    end

    true
  end
  
  # Get the stylized name of the scraper this has been differentiated to.
  # This could be done with a simple `uppercase` but it has not to leave space for
  # other services (may have a space in the name, be TikTok etc.) This comment can
  # be removed when it's obvious in the switch statement below
  def name_for_differentiated_type
    case Figaro.env.DIFFERENTIATED_TYPE
    when "instagram"
      "Instagram"
    when "facebook"
      "Facebook"
    end
  end
end
