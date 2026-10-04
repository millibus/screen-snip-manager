# Manual regression checklist

Use this checklist before tagging a release or shipping a build. Run only in a separate macOS test account with synthetic clipboard data, empty Gemini key, and no personal application windows. Record commit, macOS, architecture, Xcode, date, and pass/fail/blocked for each item; an unchecked box is not evidence of success. See [privacy guidance](../SECURITY.md).

## Overlay and focus

- [ ] Open overlay (hotkey or menu). Type in search; list filters. Select an entry with Enter or click; overlay closes and content is on clipboard.
- [ ] With **Auto-paste on select** on: after selecting an entry, focus returns to the app that was frontmost before the overlay; paste (⌘V) occurs in that app. If Accessibility is not granted, a one-time hint is shown.
- [ ] Open overlay, click an image entry’s thumbnail to open image preview. Preview window appears; the previously frontmost app remains frontmost (no focus steal). Close preview; select a text entry with auto-paste on — paste targets the correct app.

## Global hotkey and permissions

- [ ] With app in background, press the configured hotkey (default ⌘⇧V). Overlay appears. If it does not, add Clipboard Manager in **System Settings → Privacy & Security → Accessibility** and enable it.
- [ ] Change hotkey in Preferences; new hotkey opens overlay, old hotkey does not.

## Data and sensitivity

- [ ] Copy a URL, then a JSON snippet, then a normal sentence. All appear in history and are not expired early.
- [ ] With **Store sensitive data (short expiry)** off, copy the synthetic detector fixture `ghp_example_not_real_token_value` (the short string `ghp_xxx` does not meet the detector length threshold). It is not stored. With the option on, it is stored and expires after the configured seconds.
- [ ] Re-copy the same text twice. Only one entry exists; its “last seen” position is updated and any expiry is refreshed.

## Pins and tags

- [ ] Pin an entry; it stays at top. Add a tag via context menu; search with `tag:tagname` filters correctly.

## Image

- [ ] Copy an image from another app. It appears in history. Select it; clipboard has the image. Paste in another app works.

## Cleanup

- [ ] Set max history to the supported minimum of 100. Add more than 100 distinct synthetic entries; oldest non-pinned entries are removed. Pinned entries are never removed by the limit.

## Review limitations and external processing

- [ ] Search for a word after character 80 of a stored long text. Record the current preview-only search limitation.
- [ ] Quit and relaunch; verify synthetic ordinary entries persist and expired entries remain hidden.
- [ ] With the Gemini key blank, confirm the image action reports missing configuration without an upload. Do not add a real key or execute a billed request as part of this checklist.
- [ ] Inspect any retained UI capture at full resolution using [the screenshot guide](images/README.md).
