# Development

## Prerequisites

- macOS 14 (Sonoma) or later.
- Full Xcode 16 or later (`xcode-select -p` should point inside `Xcode.app`, not the Command Line
  Tools). Swift 6 toolchain.

## Project layout

```
Package.swift
Info.plist                     # bundle metadata (assembled into the .app by build.sh)
AppIcon.icns                   # app icon (regenerate with make-icon.swift)
build.sh                       # compile + assemble "Always Green.app" and ./alwaysgreen
coverage.sh                    # run tests with coverage and gate Core at >= 90%
dist.sh                        # Developer ID sign + notarize + staple (release)
make-icon.swift                # render AppIcon.iconset
homebrew/always-green.rb       # Homebrew cask
Sources/
  AlwaysGreenCore/             # logic + protocols (unit-tested)
  AlwaysGreenApp/              # menu-bar app (AppKit + SwiftUI shell)
  alwaysgreen/                 # CLI
Tests/
  AlwaysGreenCoreTests/        # fakes + tests
docs/
```

## Common commands

```sh
swift build                    # build all targets
swift test                     # run the test suite
./coverage.sh                  # tests + coverage report, fails under 90% on Core
./build.sh                     # release build -> "Always Green.app" + ./alwaysgreen
./build.sh debug               # debug build
open "Always Green.app"        # run the app
./alwaysgreen status           # exercise the CLI
```

`build.sh` builds the `AlwaysGreenApp` and `alwaysgreen` products, assembles the `.app` bundle
(copying `Info.plist` and `AppIcon.icns`), drops the CLI at the repo root, and ad-hoc signs the
bundle. Pass a real identity with `CODESIGN_IDENTITY="..."` to sign otherwise (see
[DISTRIBUTION.md](DISTRIBUTION.md)).

## Testing conventions

- Tests live in `Tests/AlwaysGreenCoreTests` and target `AlwaysGreenCore` only; the app/CLI
  shells are intentionally thin and excluded from the coverage denominator.
- `JiggleEngine` is tested through fakes for all five protocols. The timer fake (`FakeTimer`)
  exposes `fire()` so tick behavior is deterministic (no real waiting).
- Aim to keep Core coverage at or above the 90% gate enforced by `coverage.sh`.

## Adding a new side effect (the DI pattern)

1. Declare a protocol in `Sources/AlwaysGreenCore/Protocols.swift`.
2. Inject it into `JiggleEngine.init` and store it.
3. Add a live implementation in `Sources/AlwaysGreenApp/LiveDependencies.swift` and wire it in
   `AppDelegate`.
4. Add a fake in the tests and cover the new behavior.

Keeping I/O behind a protocol is what preserves testability - never call a system API directly
from `JiggleEngine`.

## Regenerating the icon

```sh
swift make-icon.swift
iconutil -c icns AppIcon.iconset -o AppIcon.icns
rm -rf AppIcon.iconset
```

## Notes and gotchas

- **Case-insensitive filesystem**: target/binary names must differ by more than case
  (`AlwaysGreenApp` vs `alwaysgreen`), and the app's main executable is `AlwaysGreenApp` so it
  cannot collide with the CLI.
- **Do not add a second executable inside `Contents/MacOS/`** - it invalidates the bundle
  signature and macOS will treat the app as damaged. The CLI ships standalone.
- **Accessibility grant + ad-hoc signing**: each rebuild changes the ad-hoc signature, so macOS
  drops the grant. Re-grant after building, or use a Developer ID identity for a stable grant.
