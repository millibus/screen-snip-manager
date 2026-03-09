# Contributing

Contributions are welcome. To keep things simple:

1. **Open an issue** first for bugs or feature ideas so we can align on approach.
2. **Fork and branch** from `main`. Use a short branch name (e.g. `fix/thing` or `feat/something`).
3. **Build and test**: open `ClipboardManager.xcodeproj` in Xcode, run the **ClipboardManager** scheme, and run tests (⌘U). From the command line:  
   `xcodebuild test -project "ClipboardManager.xcodeproj" -scheme "ClipboardManager" -destination "platform=macOS"`
4. **Style**: match existing Swift style (PascalCase types, camelCase members). Prefer small, focused changes.
5. **Open a pull request** against `main` with a clear description. For behavioral changes, note how you verified (e.g. manual checklist in `docs/MANUAL_TEST_CHECKLIST.md`).

Security issues should not be reported in public issues; see [SECURITY.md](SECURITY.md).
