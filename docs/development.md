# Development

Requires macOS 27 or later, Apple Silicon, Xcode with the macOS 27 SDK and Swift 6.
An Apple Development signing identity is needed for signed local bundles.

## Layout

- `Sources/PersianaCore`: pure logic, such as the boundary split and auto-hide
  timing, covered by `Tests/PersianaCoreTests`.
- `Sources/MenuBarVisibility`: the Objective-C boundary to the private
  MenuBarClientCore visibility restriction. It fails open.
- `Sources/PersianaApp`: AppKit and SwiftUI, the status item, Accessibility reads,
  settings, onboarding and the vendored `PermissionFlow`.

## Build and install

```bash
make check
make install-dev
```

`make check` runs strict Swift formatting lint, unit tests, a signed Release bundle
build, the public source check and a syntax check of the scripts.
`scripts/build.sh` links the current macOS SDK and fails if the binary records an
older one, because macOS 27 would then draw the app without Liquid Glass.

`PERSIANA_SIGN_IDENTITY` selects an installed signing identity.
`PERSIANA_INSTALL_DIR` overrides the default `/Applications` destination. The
installer refuses to overwrite a running app and saves an existing installation in
`build.noindex/rollback-*.zip`. Builds land in `build.noindex/` so Spotlight never
lists a second Persiana: a copy outside `/Applications` cannot hide icons.

## QA notes

- Test the installed copy in `/Applications`. Run from any other folder, macOS
  hides Persiana's own icon too, so results are not meaningful.
- Persiana needs Accessibility permission. Grant it in System Settings › Privacy &
  Security › Accessibility.
- Never reset TCC or change other applications' preferences for a test.
- Do not run the build copy while rebuilding it.
