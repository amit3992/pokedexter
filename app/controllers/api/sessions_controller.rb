module Api
  class SessionsController < ApplicationController
    skip_before_action :require_login, only: [ :create ]
    protect_from_forgery with: :null_session

    # POST /api/login
    # Request body: { "email": "user@example.com" }
    # Response: { "token": "jwt_token", "user": { "id": 1, "email": "user@example.com" } }
    def create
      email = params[:email]&.downcase&.strip

      if email.blank?
        render json: { error: "Email is required" }, status: :unprocessable_entity
        return
      end

      user = User.find_by(email: email)

      if user
        token = JsonWebToken.encode(user_id: user.id)
        render json: {
          token: token,
          user: {
            id: user.id,
            email: user.email
          }
        }, status: :ok
      else
        render json: { error: "User not found" }, status: :not_found
      end
    end

    # POST /api/refresh
    # Refresh an existing token (optional feature)
    def refresh
      header = request.headers["Authorization"]

      if header.blank?
        render json: { error: "No token provided" }, status: :unauthorized
        return
      end

      token = header.split(" ").last

      begin
        decoded = JsonWebToken.decode(token)
        user = User.find(decoded[:user_id])

        new_token = JsonWebToken.encode(user_id: user.id)
        render json: {
          token: new_token,
          user: {
            id: user.id,
            email: user.email
          }
        }, status: :ok
      rescue JsonWebToken::DecodeError, JsonWebToken::ExpirationError => e
        render json: { error: "Invalid or expired token" }, status: :unauthorized
      rescue ActiveRecord::RecordNotFound
        render json: { error: "User not found" }, status: :not_found
      end
    end
  end
end
