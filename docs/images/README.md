# Real UI screenshot capture

No verified UI captures are included yet. Do not substitute mockups, generated images, or screenshots of a different revision for product evidence.

1. Use a separate macOS test account with an empty app profile and synthetic clipboard. Merely changing `HOME` does not isolate the shared clipboard or prove UserDefaults isolation.
2. Build the exact commit and record macOS, architecture, Xcode, and app version. Follow the [review guide](../REVIEW_GUIDE.md); stop if it does not compile.
3. Launch the app, keep Gemini API key blank, keep auto-paste off, and verify Preferences in the isolated profile.
4. Copy `Demo launch checklist`, pin/tag it `demo`, then search `launch`. Capture only the app overlay as `overlay.png`.
5. Capture Preferences as `preferences.png`, with the key field empty. If demonstrating an image, use an original synthetic image with no account or customer details.
6. Inspect full-resolution pixels for names, usernames/paths, account identifiers, clipboard history, key dots/values, notifications, menu-bar account indicators, and background windows. Recapture rather than relying on blur to make sensitive content safe.
7. Add an asset manifest with filename, source commit, app version, platform, capture date, demonstrated steps, synthetic-data description, and privacy-review result. Strip incidental metadata before publication and re-open the final images.

The 2026-10-02 local audit did not launch the production-profile app: startup always opens the normal store and starts the general clipboard watcher. No isolated macOS account was available for verified capture. Screenshots remain a specific pending acceptance task.
