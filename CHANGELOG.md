# Changelog

All notable changes to this project are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).

## [Unreleased]

### Removed

- **Generate UI Code** (Gemini) and the Gemini API key preference. The feature had stopped working when Google shut down `gemini-1.5-pro` on 2025-09-29, and it was the app's only network access. Any previously saved key is deleted from preferences at launch.

### Fixed

- README: Karabiner-Elements link points to the real site (`karabiner-elements.pqrs.org`).

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
