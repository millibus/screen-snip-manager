# Security

## Reporting a vulnerability

If you believe you have found a security issue in Clipboard Manager, please report it responsibly:

1. **Do not** open a public GitHub issue for security-sensitive bugs.
2. Open a **private security advisory** on GitHub: go to the repository, click **Security** → **Advisories** → **New draft security advisory**, or email the maintainer if you have a contact address.
3. Include steps to reproduce, impact, and any suggested fix if you have one.
4. Allow time for a fix before any public disclosure.

## Data and permissions

- Clipboard Manager stores history only on your Mac in `~/Library/Application Support/ClipboardManager/clipboard.sqlite`.
- No clipboard content is sent to the internet.
- The app may request **Accessibility** permission for the global hotkey and for **Auto-paste on select**. This permission is used only to simulate keyboard input into the frontmost app when you choose an entry.
