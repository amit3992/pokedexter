# Configure Rails for Railway deployment
if Rails.env.production?
  # Set host for URL generation
  Rails.application.config.action_controller.default_url_options = {
    host: ENV.fetch("RAILWAY_PUBLIC_DOMAIN", "pokeapp.up.railway.app")
  }

  # Configure asset host if needed
  # Rails.application.config.asset_host = ENV.fetch("RAILWAY_PUBLIC_DOMAIN", "pokeapp.up.railway.app")

  # Configure Active Storage service if used
  # Rails.application.config.active_storage.service = :production
end
