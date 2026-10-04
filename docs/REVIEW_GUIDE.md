# Review guide and evidence

## Audit baseline: 2026-10-02

Source: `2fb5e135489f2ff9d6a3afa0c51a2bfb6048e195` from public `main`. The earlier local source was seven commits behind; its settings and tests are not evidence for this revision. These results cover source review and local compilation/logic execution, not a distributed release.

Environment: Apple silicon (`arm64`), macOS 27.0.1 build 26A434, Xcode 27.0 build 27A266a, Swift 6.4. GRDB.swift 6.29.3 at `2cf6c756e1e5ef6901ebae16576a7e4e4b834622` was copied from an existing package cache and verified against the lockfile; no new package version was installed.

| Check | Result | Limits |
| --- | --- | --- |
| `xcodebuild build-for-testing`, Debug, macOS destination, code signing disabled | Passed: app and hosted test bundle compiled | No UI or hosted test execution, no archive/signing/notarization |
| Existing tests in a temporary unhosted Swift package | 13 passed, 0 failures | Exact copies of 5 production source files and 4 test files; different harness from Xcode |
| History scan | 10 reachable commits, 65 text blobs reviewed with heuristic patterns | No confirmed credential; synthetic token fixtures matched. Personal commit identity metadata needs maintainer privacy review; values omitted |
| App icon visual inspection | Generic clipboard graphic; no visible personal content | Provenance unverified; dimensions invalid for declared slot |
| UI/manual/screenshot checks | Blocked pending isolated macOS test account | Normal startup opens production storage and polls general clipboard |
| Gemini requests, fresh macOS 14 run, installation and release assets | Not tested | Separate runtime/distribution acceptance required |

The October 2 unhosted tests covered 2 entry-preview cases, 3 fuzzy-search cases, 5 detector cases, and 3 temporary-database cases (dedupe metadata refresh, expired-row filtering, and pin flag). The pin test does not prove retention under history-limit pressure. These historical tests did not exercise global hotkeys, pasteboard watching, UI focus, permissions, screenshots, or Gemini HTTP handling.

## October 4 corrections

The retired `gemini-1.5-pro` request has been replaced with the configurable stable `gemini-3.8-flash` default. The service lives in `Services/GeminiService.swift`, authenticates by header to a fixed HTTPS host, uses an ephemeral session, validates model/key syntax, and suppresses raw provider and transport error text. Preferences and the image action share the saved model setting. Blank model settings use the default.

The standalone package runs ten mocked service tests without app startup, clipboard/database/preferences access, credentials, or external requests:

```sh
swift test --build-system native
```

Ten tests passed locally on October 4. Coverage includes the default/custom model, header authentication and unchanged image payload, blank/malformed configuration, provider statuses, blocked/empty/malformed responses, multiple output parts, thought exclusion and safe transport errors. The same tests are included in Xcode and the standalone CI step. Real provider/account acceptance and visual Preferences acceptance remain unrun. The native SwiftPM build system is currently deprecated; it works on the checked toolchain but may need adjustment on future toolchains.

The combined unhosted harness passed **23 tests** (the original 13 plus these ten), using byte-identical current sources/tests and the existing locked GRDB cache. Unsigned `xcodebuild build-for-testing` also passed for the current app and test bundle; no app or hosted tests were launched. The existing 1376×768 app-icon and missing AccentColor warnings remain. Initial sandbox cache/manifest writes and the default SwiftPM signing build were blocked; workspace-local caches with the native SwiftPM harness and a narrowly approved host compilation resolved those environment limits.

## Reproduce build and tests

The README build command is the standard compilation route. The audit also used `-clonedSourcePackagesDirPath <isolated-cache> -disableAutomaticPackageResolution -skipPackageUpdates` to reuse the verified cached package. Paths and raw logs stay local because logs include machine-specific paths.

For the exact hosted target, **first switch to a separate macOS test account** and use only synthetic clipboard data:

```sh
xcodebuild test \
  -project ClipboardManager.xcodeproj \
  -scheme ClipboardManager \
  -destination 'platform=macOS' \
  -derivedDataPath build \
  CODE_SIGNING_ALLOWED=NO CODE_SIGNING_REQUIRED=NO
```

To reproduce the full unhosted logic check without starting `AppDelegate`, make a temporary Swift package outside this repository. Name its library target `ClipboardManager`; copy these unchanged sources into it: `Models/ClipboardEntry.swift` and `Services/{FuzzySearchService,SensitiveDataDetector,ClipboardStore,UserDefaultsKeys,GeminiService}.swift`. Copy all five `ClipboardManagerTests` files to its test target, depend on the exact locked GRDB revision, and run `swift test --build-system native`. Do not copy the application entry point, AppDelegate, watcher, or UI. Verify copied files against the source revision before interpreting results. This harness is supplemental evidence, not the repository's official Xcode test run.

## Findings that matter to a reviewer

1. The app icon file is 1376×768 while its declared slot requires 1024×1024. Xcode also warns that the named `AccentColor` is absent. Repair assets and verify the resulting app visually.
2. No verified isolated UI run or screenshots exist for this audit. A temporary `HOME` alone cannot guarantee isolation of Foundation paths, preferences, the general clipboard, or existing-instance activation. Do not silently run the app in a personal profile.
3. Source defaults disable sensitive storage, but saved preferences override defaults. Detector exclusions allow secrets embedded in JSON, URLs, or multiline text to be retained. Images are not screened and expiry is not secure erasure.
4. Gemini key storage remains UserDefaults. The October 4 corrections remove the key from the request URL and suppress raw error output. Protected credential storage remains a separate change; never test with a personal key during a portfolio demo.
5. Fuzzy search uses the preview's first 80 characters. UI claims and review expectations should reflect that limit.
6. The install script removes an existing `/Applications/ClipboardManager.app` before copying a build. It was not run. Initial review should use an isolated build rather than overwrite an installed app.
7. The license holder and icon provenance require maintainer decisions. Documentation cannot establish ownership or complete security.

Use [the manual checklist](MANUAL_TEST_CHECKLIST.md) for runtime acceptance and [release gates](../NEXT_STEPS.md) before calling a download ready. Apple's [notarization documentation](https://developer.apple.com/documentation/security/notarizing-macos-software-before-distribution) describes a separate distribution gate. No council review or QA Shuttle approval is claimed.
