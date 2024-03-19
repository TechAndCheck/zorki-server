class ApplicationController < ActionController::Base
  private

    def verify_auth_key
      auth_key = params["auth_key"]

      if auth_key.nil? || auth_key != Setting.auth_key
        render json: { error: "Unauthorized key" }, status: 401
        return false
      end

      true
    end
end
