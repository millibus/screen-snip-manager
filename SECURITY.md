# Security and privacy

## Reporting

Do not publish credentials, personal clipboard contents, or sensitive exploit details in an issue. If GitHub offers **Security → Report a vulnerability**, use that private reporting route. Its availability depends on repository settings. If unavailable, open only a non-sensitive request for a private reporting channel; wait for the maintainer to provide one. No private email address is published here.

Include the affected commit/version, impact, and steps using synthetic data. Do not include a real database, preferences export, API request URL, or unredacted log. No response-time or security-support guarantee is currently established.

## Data flow and limits

The watcher checks the general macOS clipboard every 0.5 seconds while the app runs. Text and PNG/TIFF-derived images are stored in SQLite under `~/Library/Application Support/ClipboardManager/`. This code does not implement application-level database encryption. OS account protections and disk encryption are separate controls.

On a fresh profile, `storeSensitiveData` is false, expiry is 60 seconds, and auto-paste is false. `AppDelegate.registerDefaultPreferences` registers fallback defaults; existing UserDefaults values take precedence. Do not infer another user's effective settings from the source defaults.

Sensitive detection is heuristic text matching. Short secrets, private prose, secrets embedded in URLs/JSON/multiline code, and image contents can be stored. Detected text is skipped with the setting off, or given an expiry with it on. Expired rows are hidden from queries and deleted by a 60-second timer while the app runs. Deletion does not establish secure erasure from SQLite pages, journals, filesystem snapshots, or backups. Pinning prevents history-limit trimming, not sensitive expiry. Turning the sensitive setting off does not purge earlier history.

## Optional external processing

**Generate UI Code** reads the configured key and sends the selected stored image plus a prompt to Google's Gemini API. Generated HTML is copied to the general clipboard. That request can incur provider charges and is subject to provider terms. Keep the key blank and do not use the action when testing offline workflows.

The key is stored in UserDefaults, not Keychain. Requests now send it in the `x-goog-api-key` header over HTTPS, outside the URL, using an ephemeral session. Error messages omit raw provider bodies and transport descriptions. Do not share preferences, request headers, or unredacted network logs. The model defaults to `gemini-3.8-flash` and is configurable in Preferences; model IDs cannot change the fixed Google API host or inject a URL/query. Google's [release notes](https://ai.google.dev/gemini-api/docs/changelog) record the old `gemini-1.5-pro` shutdown on September 29, 2025. Mocked tests cover request construction and response handling; real account/API acceptance remains unverified. There is no claim that all data always remains on the Mac.

## Safe review and screenshots

Use a separate macOS account or verified isolated test environment. A temporary `HOME` value alone is insufficient proof that Foundation paths, preferences, general clipboard, and existing app activation are isolated. The app has no supported demo/profile mode. Hosted Xcode tests launch the app and can start capture; use build-for-testing on a personal account and run hosted/manual tests only after isolation.

Keep keys blank, use invented text and images, disable notifications, capture only the app, and inspect every pixel before publishing. Quit the app before any manual removal of its test data; never delete a user's history as part of routine review. See the [capture guide](docs/images/README.md).
