# Changelog

All notable changes to this project are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).

## [Unreleased]

### Fixed

- Generate UI Code no longer calls the retired Gemini 1.5 Pro endpoint. The default is Gemini 3.8 Flash; Preferences accepts another supported image-input/text-output model ID.
- Gemini keys travel in the authentication header instead of the request URL. Provider and transport errors no longer echo raw private response text.
- Corrected Karabiner-Elements documentation, source/release status and unsupported launch-argument guidance.

### Added

- Standalone mocked Gemini regression tests (`swift test --build-system native`), also included in the Xcode test target. They never launch the app or read the clipboard, production preferences, database, or real keys.

## [1.0.0] - 2026-03-08

### Added

- Searchable clipboard history for text and images.
- Fuzzy search with keyboard navigation.
- Pin and tag support; filter by tag with `tag:name`.
- Optional sensitive-data detection with short expiry (off by default).
- Global hotkey (default ⌘⇧V) and menu bar access.
- Optional Karabiner trigger via `clipboardmanager://show`.
- Auto-paste on select (requires Accessibility permission when enabled).
- Local install script (`scripts/build-and-install.sh`) and DMG packaging script (`scripts/create-dmg.sh`).
- Unit tests for core services; manual regression checklist in `docs/MANUAL_TEST_CHECKLIST.md`.

### Changed

- Sensitive-data heuristics tightened so URLs, JSON, and code are not treated as sensitive.
- Re-copying an entry now refreshes expiry and sensitivity metadata (dedupe fix).
- Image preview window no longer activates the app, preserving focus for auto-paste.
- Auto-paste checks Accessibility permission and shows a one-time hint if missing.

### Fixed

- Deduplicated entries no longer retain stale expiry or sensitivity after re-copy.
