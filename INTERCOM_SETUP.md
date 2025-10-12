# Intercom Identity Verification Setup

This guide explains how to configure Intercom's Identity Verification (Messenger Security) for the PokeApp.

> **📦 Deploying to Railway?** Check out [RAILWAY_INTERCOM_SETUP.md](./RAILWAY_INTERCOM_SETUP.md) for Railway-specific instructions with environment variables.

## Why Identity Verification?

When Identity Verification is enabled in your Intercom workspace, it requires a cryptographic hash (`user_hash`) to verify that user data sent from your app is legitimate. This prevents malicious users from impersonating other users in Intercom conversations.

## Error Without Identity Verification

If you see this error:
```
Intercom Messenger error: Missing user_hash or intercom_user_jwt.
A valid user_hash or intercom_user_jwt is required to authenticate users
when Messenger Security is enforced.
```

Follow the steps below to fix it.

## Setup Steps

### 1. Get Your Identity Verification Secret from Intercom

1. Log in to your Intercom workspace
2. Go to **Settings** → **Installation** → **Web**
3. Scroll down to **Identity Verification**
4. Copy the **Identity Verification Secret** (it looks like a random string of characters)

### 2. Add the Secret to Rails Credentials

Open your Rails credentials file for editing:

```bash
EDITOR="nano" bin/rails credentials:edit
```

Or use your preferred editor (vim, code, etc.):

```bash
EDITOR="code --wait" bin/rails credentials:edit
```

Add the following section to your credentials file:

```yaml
intercom:
  identity_verification_secret: YOUR_SECRET_HERE
```

Replace `YOUR_SECRET_HERE` with the actual secret you copied from Intercom.

Save and close the file. Rails will encrypt and save your credentials.

### 3. Verify the Configuration

After saving, verify the secret is accessible:

```bash
bin/rails runner "puts Rails.application.credentials.dig(:intercom, :identity_verification_secret)"
```

This should output your secret (not nil).

### 4. Restart Your Rails Server

```bash
# Stop your current server (Ctrl+C)
# Then restart
bin/dev
```

### 5. Test Intercom Messenger

1. Log in to your PokeApp
2. The Intercom Messenger widget should load without errors
3. Check your browser's JavaScript console - there should be no Intercom errors
4. Try sending a test message to verify it works

## How It Works

The implementation consists of three parts:

### 1. Helper Method (`app/helpers/application_helper.rb`)

```ruby
def intercom_user_hash(user_identifier)
  secret = Rails.application.credentials.dig(:intercom, :identity_verification_secret)
  return nil unless secret

  OpenSSL::HMAC.hexdigest(
    OpenSSL::Digest.new("sha256"),
    secret,
    user_identifier.to_s
  )
end
```

This generates an HMAC SHA-256 hash of the user's ID using your Intercom secret.

### 2. View Integration (`app/views/layouts/application.html.erb`)

```javascript
window.intercomSettings = {
  api_base: "https://api-iam.intercom.io",
  app_id: "lw02a3kn",
  user_id: "<%= current_user.id %>",
  email: "<%= j current_user.email %>",
  created_at: <%= current_user.created_at.to_i %>,
  user_hash: "<%= intercom_user_hash(current_user.id) %>"
};
```

The `user_hash` field authenticates the user data with Intercom.

## Production Deployment

### For Railway

If deploying to Railway, the credentials are already encrypted in your repository. Just ensure:

1. Your `config/master.key` is set as the `RAILS_MASTER_KEY` environment variable in Railway
2. This is usually already configured in your Railway settings

### For Heroku

The credentials file works automatically if you've set the `RAILS_MASTER_KEY` config var.

### For Kamal/Docker

Ensure your `config/master.key` is included in your deployment or set as an environment variable:

```bash
export RAILS_MASTER_KEY=$(cat config/master.key)
```

## Troubleshooting

### "user_hash is empty or null" in browser console

- Verify the secret is in credentials: `bin/rails credentials:show`
- Check the helper method is being called correctly
- Restart your Rails server

### "Invalid user_hash" error

- Double-check you copied the correct secret from Intercom
- Ensure there are no extra spaces or quotes around the secret in credentials
- Try regenerating the secret in Intercom settings

### Changes not taking effect

- Clear your browser cache and cookies for localhost:3000
- Do a hard refresh (Cmd+Shift+R on Mac, Ctrl+Shift+R on Windows)
- Restart your Rails server

## Security Notes

- Never commit `config/master.key` to version control (it's already in `.gitignore`)
- Never expose the Identity Verification secret in client-side code
- The secret is safely stored in encrypted Rails credentials
- The `user_hash` can be safely sent to the client - it's a cryptographic proof, not the secret itself

## References

- [Intercom Identity Verification Documentation](https://www.intercom.com/help/en/articles/183-enable-identity-verification-for-web-and-mobile)
- [Rails Credentials Guide](https://edgeguides.rubyonrails.org/security.html#custom-credentials)
