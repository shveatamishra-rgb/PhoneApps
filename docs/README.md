# Hosted pages (GitHub Pages)

These static pages provide the public Privacy Policy and Terms of Use URLs that
App Store Connect requires for Divine Stillness Om.

## Enable once

1. Push this repo to `github.com/shveatamishra-rgb/PhoneApps`.
2. Repo **Settings ▸ Pages ▸ Build and deployment**: Source = **Deploy from a
   branch**, Branch = **main**, Folder = **/docs**. Save.
3. After ~1 minute the pages are live at:
   - Privacy: `https://shveatamishra-rgb.github.io/PhoneApps/divine-stillness/privacy/`
   - Terms:   `https://shveatamishra-rgb.github.io/PhoneApps/divine-stillness/terms/`

Use the Privacy URL in App Store Connect (App Privacy + the app's Privacy Policy
field) and as the Support URL fallback. Both URLs are already referenced in the
app's paywall/Settings copy targets and in `iPhone/DivineStillness/Docs/APP_STORE_METADATA.md`.

Adding a new app later: drop another folder beside `divine-stillness/`.
