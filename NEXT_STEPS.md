# Next steps (1.0 release)

Use this file when you return to the project to see what’s done and what’s left for a full 1.0 launch.

---

## Already done (1.0 readiness)

- **Sensitive data**: Heuristics tightened (URLs, JSON, code not treated as sensitive); default “store sensitive” set to off.
- **Dedupe**: Re-copying an entry now refreshes `expires_at` and `is_sensitive` in `ClipboardStore`.
- **Preview focus**: Image preview window no longer activates the app; auto-paste target stays correct.
- **Auto-paste**: Accessibility trust check and one-time hint if permission is missing; README updated.
- **Tests**: `ClipboardStoreTests` (dedupe, expiry, pinned); `SensitiveDataDetector` false-positive tests; manual checklist at `docs/MANUAL_TEST_CHECKLIST.md`.
- **Docs**: `CHANGELOG.md`, `SECURITY.md`, `CONTRIBUTING.md`; license/copyright aligned; README links and roadmap updated.

---

## Before calling it 1.0 launch

1. **Screenshots**  
   Run the app, capture overlay and Preferences, and add:
   - `docs/images/overlay.png`
   - `docs/images/preferences.png`  
   See `docs/images/README.md`.

2. **Tag and release**  
   - Create a git tag, e.g. `v1.0.0`.  
   - (Optional) Create a GitHub Release with that tag; attach a built `.dmg` or `.zip` of `ClipboardManager.app` (build/export per README “Distribution”, then `./scripts/create-dmg.sh` if using the script).

3. **Optional**  
   - **CI release workflow**: On tag push, build, sign/notarize, package, and upload to GitHub Releases (see README “CI enhancements for release packaging artifacts”).  
   - **Homebrew tap**: Publish a cask that points at the release asset so users can `brew install --cask clipboard-manager` after tapping.

---

## Quick reference

- **Local install (developer):** `./scripts/build-and-install.sh`
- **Create DMG for distribution:** `./scripts/create-dmg.sh [path/to/ClipboardManager.app]`
- **Manual regression:** `docs/MANUAL_TEST_CHECKLIST.md`
- **Version in app:** `ClipboardManager/Resources/Info.plist` and Xcode project → 1.0 (build 1)
