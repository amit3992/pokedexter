module ApiAuthenticatable
  extend ActiveSupport::Concern

  included do
    before_action :authenticate_api_request!
    attr_reader :current_api_user
  end

  private

  # Authenticate the API request using JWT token from Authorization header
  def authenticate_api_request!
    @current_api_user = authorize_request
  rescue JsonWebToken::DecodeError => e
    render json: { error: "Invalid token" }, status: :unauthorized
  rescue JsonWebToken::ExpirationError => e
    render json: { error: "Token has expired" }, status: :unauthorized
  rescue ActiveRecord::RecordNotFound => e
    render json: { error: "User not found" }, status: :unauthorized
  end

  # Extract and decode JWT token from Authorization header
  def authorize_request
    header = request.headers["Authorization"]
    return nil unless header

    token = header.split(" ").last
    decoded = JsonWebToken.decode(token)
    User.find(decoded[:user_id])
  end
end
