module ApplicationHelper
  # Generate Intercom Identity Verification user_hash
  # This is required when Intercom's Messenger Security is enabled
  #
  # Checks ENV variable first (for Railway/Heroku), then falls back to Rails credentials
  #
  # @param user_identifier [String, Integer] The user's ID or email
  # @return [String, nil] The HMAC SHA-256 hash or nil if secret is not configured
  def intercom_user_hash(user_identifier)
    secret = ENV["INTERCOM_IDENTITY_VERIFICATION_SECRET"] ||
             Rails.application.credentials.dig(:intercom, :identity_verification_secret)
    return nil unless secret

    OpenSSL::HMAC.hexdigest(
      OpenSSL::Digest.new("sha256"),
      secret,
      user_identifier.to_s
    )
  end
end
