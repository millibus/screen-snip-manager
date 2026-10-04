# Architecture

`ClipboardManagerApp` delegates lifecycle setup to `AppDelegate`. Startup registers preference defaults, opens `ClipboardStore.shared`, starts the general clipboard watcher, installs menu UI and the Carbon hotkey, and schedules expired-row cleanup every 60 seconds.

```text
macOS general clipboard → PasteboardWatcher → SensitiveDataDetector (text only)
                                           → ClipboardStore / GRDB / SQLite
menu bar or hotkey → SearchOverlayView → FuzzySearchService → selection
selection → general clipboard → optional simulated paste
image action → GeminiService → Google API → HTML to general clipboard
```

- `Models/ClipboardEntry.swift`: row presentation and 80-character text preview.
- `Services/ClipboardStore.swift`: migration, hash deduplication, expiry filtering, pin/tag updates, history trimming. Its `dbPath` initializer supports tests; the production singleton uses Application Support.
- `Services/PasteboardWatcher.swift`: polls at 0.5 seconds; text takes priority over image representations.
- `Services/UserDefaultsKeys.swift`: preference keys/defaults.
- `Services/GeminiService.swift`: optional image-to-HTML requests using a configurable Gemini model, header authentication, and injectable HTTP session for mocked tests.
- `UI/`: SwiftUI views hosted by AppKit controllers/panels; global shortcuts use Carbon.
- `ClipboardManagerTests/`: model, fuzzy-search, detector, and temporary-database tests. The Xcode target is hosted by the app.

There is no supported launch argument for an isolated profile or demo dataset. UI and hosted-test execution must account for real clipboard capture and existing instances. See [SECURITY.md](../SECURITY.md).
