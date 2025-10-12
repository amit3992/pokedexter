# Adding Intercom Secret to Railway

This guide shows you how to add your Intercom Identity Verification secret to Railway for production deployment.

## Prerequisites

1. Get your Intercom Identity Verification secret:
   - Log in to Intercom
   - Go to **Settings** → **Installation** → **Web**
   - Scroll to **Identity Verification**
   - Copy the secret key

## Option 1: Using Rails Credentials (Recommended)

This approach uses Rails encrypted credentials, which is more secure and consistent with your existing setup.

### Step 1: Add Secret to Encrypted Credentials Locally

```bash
# Open your credentials file for editing
EDITOR="nano" bin/rails credentials:edit

# Or use VS Code
EDITOR="code --wait" bin/rails credentials:edit
```

Add the Intercom secret to the file:

```yaml
intercom:
  identity_verification_secret: your_secret_here_from_intercom

# Keep existing content, like:
secret_key_base: a8156a81e262ba2c8a366b7129de158d2c9d64b4cd820c1c4d4026541868febd9179391c585ee2dddb2285afd6f18138bffe73178dd8aee7c23125a8a2d89a5d
```

Save and close. Rails will encrypt the file automatically.

### Step 2: Verify RAILS_MASTER_KEY is Set in Railway

1. Go to your [Railway dashboard](https://railway.app/dashboard)
2. Select your PokeApp project
3. Click on your service/deployment
4. Go to the **Variables** tab
5. Check if `RAILS_MASTER_KEY` exists

**If RAILS_MASTER_KEY is already set**: ✅ You're good! Skip to Step 3.

**If RAILS_MASTER_KEY is missing**:
```bash
# Get your master key locally
cat config/master.key
```

Then in Railway:
1. Click **+ New Variable**
2. Variable name: `RAILS_MASTER_KEY`
3. Variable value: Paste the content from your `config/master.key`
4. Click **Add**

### Step 3: Commit and Push Your Changes

```bash
git add config/credentials.yml.enc
git commit -m "Add Intercom Identity Verification secret to credentials"
git push
```

**Note**: You're committing the **encrypted** credentials file, which is safe. Never commit `config/master.key`!

### Step 4: Verify Deployment

After Railway redeploys:

1. Visit your Railway app URL
2. Log in
3. Check browser console (F12) - no Intercom errors should appear
4. The Intercom Messenger should load successfully

---

## Option 2: Using Railway Environment Variable (Alternative)

This approach uses Railway environment variables directly. Choose this if you prefer managing secrets in Railway's UI.

### Step 1: Update the Helper Method

Update `app/helpers/application_helper.rb` to check environment variables first:

```ruby
module ApplicationHelper
  # Generate Intercom Identity Verification user_hash
  # Checks ENV first, then falls back to Rails credentials
  def intercom_user_hash(user_identifier)
    secret = ENV['INTERCOM_IDENTITY_VERIFICATION_SECRET'] ||
             Rails.application.credentials.dig(:intercom, :identity_verification_secret)
    return nil unless secret

    OpenSSL::HMAC.hexdigest(
      OpenSSL::Digest.new("sha256"),
      secret,
      user_identifier.to_s
    )
  end
end
```

### Step 2: Add Environment Variable in Railway

1. Go to your [Railway dashboard](https://railway.app/dashboard)
2. Select your PokeApp project
3. Click on your service
4. Go to the **Variables** tab
5. Click **+ New Variable**
6. Add:
   - **Variable name**: `INTERCOM_IDENTITY_VERIFICATION_SECRET`
   - **Variable value**: Your Intercom secret (paste it here)
7. Click **Add**

Railway will automatically redeploy your app.

### Step 3: Add to Local Development (Optional)

For local development, you can either:

**A. Use Rails credentials** (add the secret as shown in Option 1, Step 1)

**B. Use a `.env` file** (requires `dotenv-rails` gem):

```bash
# In your .env file (don't commit this!)
INTERCOM_IDENTITY_VERIFICATION_SECRET=your_secret_here
```

### Step 4: Commit and Deploy

```bash
git add app/helpers/application_helper.rb
git commit -m "Update Intercom helper to support ENV variable"
git push
```

### Step 5: Verify Deployment

Same as Option 1, Step 4.

---

## Comparison: Which Option to Choose?

| Feature | Option 1: Rails Credentials | Option 2: ENV Variable |
|---------|----------------------------|------------------------|
| **Security** | ✅ Encrypted in repo | ⚠️ Only in Railway UI |
| **Version Control** | ✅ Changes tracked in git | ❌ Changes not tracked |
| **Consistency** | ✅ Matches JWT secret pattern | ⚠️ Different from existing secrets |
| **Setup Complexity** | ⚠️ Requires master key | ✅ Simple UI-only change |
| **Local Development** | ✅ Works automatically | ⚠️ Needs .env or manual setup |
| **Team Collaboration** | ✅ Easy to share encrypted | ⚠️ Each dev needs secret separately |

**Recommendation**: Use **Option 1** (Rails Credentials) for consistency and better security practices.

---

## Troubleshooting

### "Secret is nil" Error

**Check your credentials locally:**
```bash
bin/rails runner "puts Rails.application.credentials.dig(:intercom, :identity_verification_secret)"
```

Should output your secret, not `nil`.

**Check master key in Railway:**
- Verify `RAILS_MASTER_KEY` variable exists in Railway
- Verify it matches your local `config/master.key`

### Deployment Successful but Still Getting Errors

1. **Hard refresh** your browser (Cmd+Shift+R / Ctrl+Shift+R)
2. **Clear Railway cache** and redeploy:
   ```bash
   git commit --allow-empty -m "Trigger Railway rebuild"
   git push
   ```
3. **Check Railway logs**:
   - Go to Railway dashboard → your service → **Deployments** tab
   - Click on the latest deployment
   - Check logs for any errors

### Railway Not Redeploying After Push

1. Check the **Deployments** tab in Railway
2. Ensure GitHub integration is connected
3. Check if auto-deploy is enabled (Settings → Deploy → Auto Deploy)
4. Try manual redeploy: Click "⋯" → "Redeploy"

### Master Key Doesn't Match

If you get credential decryption errors:

```bash
# Backup your current credentials
cp config/credentials.yml.enc config/credentials.yml.enc.backup

# Regenerate (only if absolutely necessary)
rm config/credentials.yml.enc config/master.key
EDITOR="nano" bin/rails credentials:edit
# Re-add all your secrets

# Update Railway with new master key
cat config/master.key
# Copy and update RAILS_MASTER_KEY in Railway
```

---

## Verification Checklist

After deployment, verify:

- [ ] Intercom Messenger appears on your Railway app
- [ ] No JavaScript console errors about "Missing user_hash"
- [ ] You can send a test message in Intercom
- [ ] User identification works correctly in Intercom dashboard
- [ ] The fix works after logging out and back in

---

## Getting Help

If you're still having issues:

1. Check Railway deployment logs
2. Check browser console for specific error messages
3. Verify the secret is correct in Intercom dashboard
4. Try the alternative option if one isn't working

## Security Reminders

- ✅ DO commit `config/credentials.yml.enc` (it's encrypted)
- ❌ NEVER commit `config/master.key` (it decrypts credentials)
- ❌ NEVER expose secrets in client-side code
- ✅ DO keep `RAILS_MASTER_KEY` secure in Railway
- ✅ DO use different secrets for staging/production if you have multiple environments
