# Persiana

Public macOS menu bar app that hides chosen menu bar icons. Swift 6, SwiftPM, macOS 27+, Apple Silicon.

- Support English and Spanish UI through `localized(en, es)`; keep code and documentation in English.
- Pure logic belongs to PersianaCore and is covered by tests; AppKit and UI belong to PersianaApp, MainActor isolated.
- Hiding uses the MenuBarClientCore assessment assertion behind the Objective-C `MenuBarVisibility` target only.
- Always fail open: if the private API is missing or fails, show every icon.
- Persiana's own status item is the boundary: apps left of it are hidden, apps right of it stay visible.
- Hiding is per app; an app with several icons hides and shows them together. System items stay visible.
- Read item positions only while expanded; hidden items report stale AX frames.
- Accessibility is used only to read menu bar item positions. No Screen Recording, no keystrokes; the only network access is the Sparkle update check against GitHub Releases.
- The app must run from /Applications; elsewhere macOS hides Persiana's own icon too.
- Local installs are Apple Development signed with the stable bundle ID `com.stevenacz.Persiana`.
- Builds must link the current SDK so macOS 27 draws Liquid Glass; `scripts/build.sh` enforces it.
- The auto-hide timer and any polling run only while icons are shown.
- Tutorial animations run only while its window is visible and are dropped on close.
- PermissionFlow is vendored: never edit the copy; re-vendor from the canonical package.
- Never reset TCC or modify other applications' preferences for tests.
- Do not test the build bundle while rebuilding it; use the installed copy.
- No generated explanatory comments. Only document essential constraints.
- Full gate: make check (Swift format lint, swift test, signed Release bundle, public source check).
- Releases follow docs/releasing.md: every release ships the DMG, the ZIP and appcast.xml, and `CFBundleVersion` strictly increases.
- Verification is local only: there is no hosted CI. Do not add GitHub Actions workflows.
- Never commit signing identities, Team IDs, personal paths or private data.
- Commits read as the maintainer's own work: no AI attribution or co-author trailers.
