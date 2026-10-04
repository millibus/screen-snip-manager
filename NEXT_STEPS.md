# Release readiness work

The version fields and historical changelog do not establish a distributable release. Work from current `main`; the 2026-10-02 audit found an older local checkout seven commits behind the fetched public branch.

## Before a public portfolio walkthrough

1. Resolve any current compile/test failures in [the review guide](docs/REVIEW_GUIDE.md), then run the existing hosted tests in an isolated macOS account.
2. Complete the [manual checklist](docs/MANUAL_TEST_CHECKLIST.md) with synthetic data on macOS 14 and a current supported macOS version. Verify search limits, hotkeys, permission denial, persistence, dedupe, pin/tag behavior, expiry, and image preview.
3. Capture real UI using [the screenshot guide](docs/images/README.md). Record exact commit/platform and inspect every pixel for private data.
4. Review the privacy model: heuristic bypasses, SQLite retention, lack of safe demo mode, Gemini key storage/request handling, and external-service failure behavior. Treat API execution as a separately authorized test.
5. Confirm copyright attribution and app-icon provenance without silently changing licensing. Preserve GRDB notices.

## Before distributing an installer

- Build an archive from the reviewed revision; verify version/build metadata and architectures.
- Sign with the authorized distribution identity, notarize, staple, and verify the exported artifact. Record checksums and fresh-machine installation/launch/uninstall results.
- Verify update and data-retention expectations, artifact contents, dependency notices, and the support/security-reporting route.
- Only then prepare a version tag and release for maintainer approval. Packaging a DMG alone does not satisfy these gates.

No signing, notarization, publication, or visibility change was performed by the documentation audit.
