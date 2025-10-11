class JsonWebToken
  # Secret key to encode/decode tokens
  # Uses credentials if available, falls back to secret_key_base
  SECRET_KEY = Rails.application.credentials.dig(:jwt, :secret_key) || Rails.application.secret_key_base

  # Encode a payload with expiration time
  # @param payload [Hash] The data to encode
  # @param exp [Integer] Expiration time in hours (default: 24)
  # @return [String] The JWT token
  def self.encode(payload, exp = 24.hours.from_now)
    payload[:exp] = exp.to_i
    JWT.encode(payload, SECRET_KEY)
  end

  # Decode a JWT token
  # @param token [String] The JWT token to decode
  # @return [HashWithIndifferentAccess] The decoded payload
  # @raise [JWT::DecodeError] If token is invalid or expired
  def self.decode(token)
    body = JWT.decode(token, SECRET_KEY)[0]
    HashWithIndifferentAccess.new body
  rescue JWT::ExpiredSignature => e
    raise ExpirationError, "Token has expired"
  rescue JWT::DecodeError => e
    raise DecodeError, "Invalid token"
  end

  # Custom exception classes
  class ExpirationError < StandardError; end
  class DecodeError < StandardError; end
end
