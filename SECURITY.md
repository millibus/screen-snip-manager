# Security

## Reporting a vulnerability

If you believe you have found a security issue in Clipboard Manager, please report it responsibly:

1. **Do not** open a public GitHub issue for security-sensitive bugs.
2. Open a **private security advisory** on GitHub: go to the repository, click **Security** → **Advisories** → **New draft security advisory**, or email the maintainer if you have a contact address.
3. Include steps to reproduce, impact, and any suggested fix if you have one.
4. Allow time for a fix before any public disclosure.

## Data and permissions

- Clipboard Manager stores history only on your Mac in `~/Library/Application Support/ClipboardManager/clipboard.sqlite`.
- By default, no clipboard content is sent to the internet. The one exception is the optional **Generate UI Code** feature: if you configure a Gemini API key in Preferences and explicitly trigger it on an image entry, that image is uploaded to Google's Gemini API (`generativelanguage.googleapis.com`) to generate HTML. No other clipboard content ever leaves your Mac, and nothing is sent unless you set a key and invoke the feature yourself.
- The Gemini API key is stored in the app's preferences (`UserDefaults`), not the macOS Keychain. Treat it as a low-value, revocable key.
- The app may request **Accessibility** permission for the global hotkey and for **Auto-paste on select**. This permission is used only to simulate keyboard input into the frontmost app when you choose an entry.
