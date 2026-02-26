# Clipboard Manager (macOS)

Menu bar app that keeps a searchable history of clipboard items: text and images, with fuzzy search, pins, tags, and optional sensitive-data handling.

## Project status

v1.0. Core workflows are functional and covered by unit tests.

## Features

- Searchable clipboard history for text and images
- Fuzzy search with keyboard navigation
- Pin and tag support (`tag:name` filter)
- Optional sensitive-data handling with short expiry
- Global hotkey support and menu bar access
- Optional Karabiner trigger via custom URL scheme

## Requirements

- macOS 14+
- Xcode 15+ (for building)

## Build and run

1. Open `ClipboardManager.xcodeproj` in Xcode.
2. Resolve Swift Package dependencies (GRDB) if prompted.
3. Select the **ClipboardManager** scheme and run (⌘R).

The app runs as a menu bar item (clipboard icon). It does not appear in the Dock (`LSUIElement`).

## Running tests

```bash
xcodebuild test -project "ClipboardManager.xcodeproj" -scheme "ClipboardManager" -destination "platform=macOS"
```

## Distribution

To ship a build for others (e.g. GitHub Releases or direct download):

1. **Archive**: In Xcode, choose **Product → Archive**.
2. **Code signing**: In the **ClipboardManager** target, open **Signing & Capabilities** and set your **Team**. Use "Sign to Run Locally" for local installs, or full signing for distribution. The project uses automatic signing; ensure the **Clipboard Manager** app is signed before exporting.
3. **Notarization** (required for macOS 10.15+): For direct download outside the Mac App Store, notarize the app so Gatekeeper does not block it. After archiving, choose **Distribute App** → **Developer ID** (or **Copy App** then notarize the copied app with `xcrun notarytool submit` and staple with `xcrun stapler staple`). See [Apple’s notarization guide](https://developer.apple.com/documentation/security/notarizing_mac_software_before_distribution) for credentials and steps.
4. **Export**: Distribute the archive (e.g. **Distribute App** → Copy App or Upload to notary) and place **Clipboard Manager.app** in a `.zip` or `.dmg` for users. They can install to `/Applications` or elsewhere.

## Usage

- **Show overlay**: Press the configured hotkey (default **⌘⇧V**) or click the menu bar icon. You can also use the Karabiner “hold F6” rule (see below).
- **Search**: Type in the search field to filter by content. Use `tag:name` at the start of the query to filter by tag.
- **Select**: Click an entry or press Enter to copy it to the clipboard and close the overlay. Optionally enable **Auto-paste on select** in Preferences to simulate ⌘V after copying.

## Preferences

Open **Preferences…** from the menu bar (⌘,) to configure:

- **Auto-paste on select** — After choosing an entry, simulate ⌘V in the frontmost app.
- **Max history** — Maximum number of entries to keep (100–10,000). Oldest non-pinned entries are removed when exceeded.
- **Hotkey** — Global shortcut to show the overlay (default ⌘⇧V). Click **Change** and press the new key combination.
- **Sensitive data** — When **Store sensitive data (short expiry)** is on, content that looks like passwords/tokens is stored with a short expiry. When off, such content is not stored. **Sensitive expiry** sets that expiry in seconds (10–86400).

## Data

- History is stored in `~/Library/Application Support/ClipboardManager/clipboard.sqlite`.
- Duplicate content (by hash) is deduplicated; re-copying the same item updates its position.
- Pinned entries stay at the top and are not removed by the max-history limit.

## Global hotkey and permissions

The overlay hotkey is registered via the Carbon API. If it does not work when the app is in the background:

1. Open **System Settings → Privacy & Security → Accessibility**.
2. Add **Clipboard Manager** (or **ClipboardManager**) and ensure it is enabled.

The app does not require Accessibility for basic menu bar and overlay use; only the global hotkey may need it on some configurations.

## Karabiner setup (optional)

You can trigger the overlay by holding **F6** (or another key) using [Karabiner-Elements](https://karabiner-elements.pikelet.audio/).

1. Copy the included config into your Karabiner rules:
   - **File**: `Karabiner/clipboard-on-hold.json`
   - In Karabiner-Elements, use **Complex Modifications → Add rule → Import more rules from the internet** or paste the contents of the JSON into a new rule.
2. The rule runs: `open 'clipboardmanager://show'` when you hold F6 for 250 ms. Ensure Clipboard Manager is running so the URL is handled.

If the URL does not activate an already-running instance, use this in the rule instead:

```json
"to_if_held_down": [{ "shell_command": "open -a ClipboardManager --args show" }]
```

(Adjust the app name if you renamed it.)

## App icon

The project includes an **AppIcon** set in `ClipboardManager/Resources/Assets.xcassets`. To use a custom icon, add your own 16×16 through 512×512 (or a single 1024×1024) assets to **AppIcon.appiconset** in Xcode.

## Screenshots

Add screenshots before publishing to improve first impressions:

- Overlay search view: `docs/images/overlay.png`
- Preferences panel: `docs/images/preferences.png`

## Roadmap

- [x] Clipboard history for text and images
- [x] Fuzzy search, pins, and tags
- [x] Sensitive-content detection and expiry
- [x] Unit test target for core service logic
- [ ] Broader test coverage for persistence edge cases
- [ ] CI enhancements for release packaging artifacts

## Contact

- **Source:** [GitHub](https://github.com/millibus/screen-snip-manager)
- **Bugs and suggestions:** [Open an issue](https://github.com/millibus/screen-snip-manager/issues)

## License

MIT License. See `LICENSE`.
