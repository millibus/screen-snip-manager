# Project Overview

Clipboard Manager is a macOS menu bar app that captures clipboard text and images into a searchable local history with fuzzy search, pinning, tags, global hotkey access, and optional short-lived storage for sensitive content. It uses a hybrid SwiftUI/AppKit architecture and persists data in a local SQLite database via GRDB.

## Tech Stack
- Swift 5 (SwiftUI + AppKit)
- GRDB.swift for SQLite persistence
- Carbon API for global hotkeys
- CryptoKit for content hashing and deduplication
- Local SQLite database at `~/Library/Application Support/ClipboardManager/clipboard.sqlite`

## Architecture

The app is organized into `Models`, `Services`, and `UI` layers. App startup is coordinated by `AppDelegate`, which wires menu bar UI, hotkey handling, pasteboard monitoring, and persistence. Clipboard changes are detected by a watcher service, stored in SQLite with deduplication/expiry rules, and rendered in a SwiftUI overlay hosted in an AppKit panel.

### Directory Structure
```text
ClipboardManager/                      Main app source
  Models/                              Clipboard data models
  Services/                            Persistence, hotkeys, watcher, search, sensitivity logic
  UI/                                  Menu bar, overlay window/view, preferences UI
  Resources/                           Info.plist and asset catalogs
ClipboardManager.xcodeproj/            Xcode project and build configuration
Karabiner/                             Optional Karabiner integration rule
README.md                              Setup, usage, and distribution documentation
```

## Key Files
- `ClipboardManager/ClipboardManagerApp.swift` - SwiftUI app entry point.
- `ClipboardManager/AppDelegate.swift` - App lifecycle wiring, URL handling, defaults registration, cleanup timer.
- `ClipboardManager/Models/ClipboardEntry.swift` - Core clipboard entry model and content type enum.
- `ClipboardManager/Services/ClipboardStore.swift` - GRDB-backed SQLite storage, schema migration, CRUD, deduplication, trimming, expiry cleanup.
- `ClipboardManager/Services/PasteboardWatcher.swift` - Polls clipboard changes and inserts normalized entries.
- `ClipboardManager/Services/HotKeyService.swift` - Registers and handles global hotkey events.
- `ClipboardManager/UI/MenuBarController.swift` - Menu bar item/menu actions and overlay coordination.
- `ClipboardManager/UI/SearchOverlayView.swift` - Searchable history UI, keyboard interactions, tag filtering.
- `ClipboardManager/UI/SearchOverlayWindow.swift` - Floating panel host for SwiftUI overlay.
- `ClipboardManager/UI/PreferencesView.swift` - User preferences UI and hotkey capture.
- `ClipboardManager/Resources/Info.plist` - Bundle metadata, URL scheme, LSUIElement behavior.
- `Karabiner/clipboard-on-hold.json` - Optional external trigger rule using `clipboardmanager://show`.

## Entry Points
- `ClipboardManager/ClipboardManagerApp.swift` (`@main ClipboardManagerApp`) starts the application.
- `ClipboardManager/AppDelegate.swift` initializes services in `applicationDidFinishLaunching(_:)`.
- `ClipboardManager/AppDelegate.swift` handles `clipboardmanager://` URLs in `application(_:open:)`.
- `ClipboardManager/UI/MenuBarController.swift` handles menu actions for show overlay, preferences, and app controls.
- `ClipboardManager/Services/HotKeyService.swift` routes global hotkey presses to overlay toggling.

## Common Tasks

### Running the Project
```bash
open "ClipboardManager.xcodeproj"
# In Xcode: select ClipboardManager scheme, resolve packages if prompted, then Run (Cmd+R)
```

### Running Tests
```bash
# No test target is currently configured.
# After adding tests in Xcode, run:
xcodebuild test -project "ClipboardManager.xcodeproj" -scheme "ClipboardManager" -destination "platform=macOS"
```

### Building
```bash
xcodebuild -project "ClipboardManager.xcodeproj" -scheme "ClipboardManager" -configuration Debug build
# For distributable builds, use Product -> Archive in Xcode.
```

## Code Patterns

### Layered App Structure
Code is separated into model, service, and UI layers with clear responsibilities: models define data shape, services encapsulate behavior/integration, and UI files coordinate display and user interaction.

### Service Singletons + Local Persistence
Core services (`ClipboardStore`, fuzzy search, sensitive-data detection) use singleton access patterns. Persistence is local-only SQLite with migrations, hash-based deduplication, max-history trimming, and periodic expiry cleanup.

### Hybrid SwiftUI/AppKit Composition
SwiftUI views are embedded in AppKit windows/controllers to support menu bar behavior, floating overlay windows, and native macOS integration points.

## Configuration
- `ClipboardManager/Resources/Info.plist` - URL scheme registration, LSUIElement menu bar mode, version/bundle metadata.
- `ClipboardManager.xcodeproj/project.pbxproj` - Build settings, deployment target (`14.0`), code signing mode, package dependencies.
- `ClipboardManager/Services/UserDefaultsKeys.swift` - UserDefaults keys for app preferences and defaults.
- `Karabiner/clipboard-on-hold.json` - Optional external hotkey trigger rule.
- `autoPasteOnSelect` - Toggles simulated paste after selecting an entry.
- `storeSensitiveData` - Enables or disables storing sensitive-looking content.
- `sensitiveExpirySeconds` - Expiration duration for sensitive entries.
- `maxHistory` - Maximum retained clipboard history size.
- `hotkeyModifiers` / `hotkeyKeyCode` - Global hotkey configuration.

## Important Conventions
- Use PascalCase for types and camelCase for properties/functions.
- Keep source organized by role in `Models/`, `Services/`, and `UI/`.
- Route user-configurable settings through centralized UserDefaults keys.
- Keep clipboard storage local; deduplicate entries by content hash.
- Treat pinned entries as high-priority and exempt from history trimming.
- Handle both menu bar and global-hotkey flows as first-class entry paths.
