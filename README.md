# Screen Snip / Clipboard Manager for macOS

A native macOS menu bar utility for finding and reusing clipboard text and images. The repository is named `screen-snip-manager`; the app, Xcode project, and executable are named **ClipboardManager**. It records items copied to the clipboard; it does not provide a screen-region capture tool.

## Status and support

The source reports version **1.0, build 1**. The [changelog](CHANGELOG.md) describes 1.0.0; these version labels are not proof of a tested, signed, notarized download. On October 4, 2026, GitHub had one unpublished `v0.1.0` draft with no assets. Treat this as a source build for evaluation until a release includes matching build and manual-test evidence. See [review evidence and limitations](docs/REVIEW_GUIDE.md) and [release gates](NEXT_STEPS.md).

- Deployment target: **macOS 14 or later**. Windows and Linux are unsupported.
- Development: Xcode with the macOS SDK and Swift Package Manager. The latest local audit used Xcode 27.0 on an Apple silicon Mac; macOS 14 compatibility still needs a run on that OS.
- Dependency: GRDB.swift, pinned to 6.29.3 in `Package.resolved`.

## What it does

- Keeps text and image clipboard history in a local SQLite database.
- Searches text previews with fuzzy matching, keyboard navigation, pins, and tags (`tag:name`).
- Opens from the menu bar or **⌘⇧V**; supports an optional Karabiner URL trigger.
- Copies a selected item; optional auto-paste requires Accessibility access.
- Optionally sends a selected image to Google's Gemini API to generate HTML. This is an external, potentially billed service; it is not needed for clipboard history and was not exercised in the local review.

## Before running

Clipboard history can include passwords, private messages, customer material, and screenshots. The app does not encrypt its database itself. Sensitive-text detection is a heuristic and does not inspect image contents; URLs, JSON, and multiline text bypass that detector. Expiry is not secure erasure. Read [security and privacy](SECURITY.md).

Use a separate macOS test account with synthetic clipboard content for evaluation and screenshots. Leave the Gemini key blank and auto-paste off. Do not launch the app or hosted Xcode tests against a personal clipboard merely to collect evidence.

## Build from source

```sh
git clone https://github.com/millibus/screen-snip-manager.git
cd screen-snip-manager
xcodebuild build-for-testing \
  -project ClipboardManager.xcodeproj \
  -scheme ClipboardManager \
  -destination 'platform=macOS' \
  -derivedDataPath build \
  CODE_SIGNING_ALLOWED=NO CODE_SIGNING_REQUIRED=NO
```

Dependency resolution may access GitHub. `build-for-testing` compiles the app and test bundle without starting the clipboard watcher. Unsigned local build success is not distribution approval. Known compile issues and the most recent actual results are recorded in [the review guide](docs/REVIEW_GUIDE.md).

For an interactive run, open `ClipboardManager.xcodeproj`, resolve packages, select the **ClipboardManager** scheme, then Run in the isolated test account. The app appears in the menu bar, not the Dock. Do not use `scripts/build-and-install.sh` for a first review: it installs into `/Applications`. Packaging scripts are developer helpers, not evidence of signing or notarization.

## Try the core workflow

1. Copy `Demo launch checklist` in the isolated account.
2. Open the clipboard menu and show the overlay, or press **⌘⇧V**.
3. Search for `launch`; choose the item to copy it back.
4. Pin the item and add the tag `demo`; search `tag:demo`.
5. Copy a synthetic image, inspect its preview, and leave **Generate UI Code** unused.
6. Open **Preferences…**. Check the limits and sensitive-data setting; keep the API-key field empty for demos.

The default history limit is 500; pinned entries are exempt from history trimming. Search operates on the first 80 text characters plus an ellipsis, not the entire stored text. Duplicate content refreshes its timestamp, expiry, and sensitivity metadata.

## Settings and permissions

- **Store sensitive data (short expiry)** defaults to **off for a fresh profile**. Previously saved preferences override defaults. Turning it on stores detected text with a default 60-second expiry; ordinary text and images have no equivalent expiry.
- **Auto-paste on select** defaults to off. If enabled, it simulates paste into the frontmost app; verify the destination with synthetic data and grant Accessibility only when needed.
- **Gemini API key** is optional and stored in UserDefaults, not Keychain. A configured key plus the image action sends that image to `generativelanguage.googleapis.com`.
- **Gemini model** defaults to `gemini-3.8-flash`, a stable model accepting images and returning text in [Google's model documentation](https://ai.google.dev/gemini-api/docs/models/gemini-3.8-flash) checked October 4, 2026. Enter another supported image-input/text-output Gemini model ID in Preferences; a blank field uses the default. The API host stays fixed. Availability, account access, quota and pricing remain provider-dependent. Requests authenticate using a header, not a key in the URL. No real API call was made to validate this change.
- History is stored at `~/Library/Application Support/ClipboardManager/clipboard.sqlite`, including SQLite companion files where present. Quitting stops capture but does not delete history.

Optional [Karabiner-Elements](https://karabiner-elements.pqrs.org/) integration is in `Karabiner/clipboard-on-hold.json` and opens `clipboardmanager://show` after holding F6. The app handles that URL; arbitrary command-line `--args show` behavior is not implemented.

## Review, contribute, and report

Start with the [review guide](docs/REVIEW_GUIDE.md), [manual checklist](docs/MANUAL_TEST_CHECKLIST.md), and [contribution guide](CONTRIBUTING.md). [Screenshot instructions](docs/images/README.md) require real UI, synthetic data, and a privacy inspection. No verified UI screenshots are included yet.

Use [GitHub issues](https://github.com/millibus/screen-snip-manager/issues) for sanitized bugs and suggestions. For confidential reports, follow [SECURITY.md](SECURITY.md); never attach your clipboard database or API key.

## Architecture and license

See [architecture](docs/ARCHITECTURE.md) and [license inventory](docs/LICENSE_INVENTORY.md). The repository contains an [MIT license](LICENSE); this documentation change does not alter licensing or assign a copyright holder.
