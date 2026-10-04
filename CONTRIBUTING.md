# Contributing and reviewing

Small, reproducible reports and focused pull requests are welcome. Use the existing `millibus` repository identity in public documentation; do not add personal contact details or local machine paths.

1. Read the [README](README.md), [security guidance](SECURITY.md), and [review guide](docs/REVIEW_GUIDE.md).
2. Start a branch from current `main`; preserve other work and do not assume a cached local branch is current. Record the commit tested.
3. For a code change, explain the user-visible problem, expected behavior, and validation. Match the existing Swift naming and directory structure.
4. Compile with the documented `build-for-testing` command. Run hosted/manual tests in an isolated macOS account using synthetic data only. Record passed, failed, blocked, and untested checks separately.
5. Open a focused pull request with platform/tool versions, test results, limitations, and reviewed UI evidence when applicable. A model or code review is not a substitute for execution evidence.

Before sharing, inspect staged files, reachable history relevant to the change, screenshot pixels, logs, and example data. Exclude database files, UserDefaults exports, keys, personal names/emails, usernames in paths, signing identities, and customer information. Use a privacy-preserving Git commit identity. Never paste a secret into a public bug report.

License ownership and asset provenance questions need maintainer decisions; contributors should not silently replace notices or relicense existing code. Packaging, signing, notarization, and publication are separate release actions.
