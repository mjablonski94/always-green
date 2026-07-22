# Always Green

A menu-bar macOS utility that keeps your Mac active and your chat status "available" by making
a tiny cursor movement on an interval derived from your screen-sleep setting.

## Features

- **Filled green circle** in the menu bar = on; **outlined green circle** = off.
- **Left-click** the icon opens the panel; **right-click** toggles on/off.
- **Interval auto-set** to half your system screen-sleep time (so a nudge always lands before the
  screen sleeps), capped under the usual ~5-minute idle threshold, and adjustable. Falls back to
  30s when screen-sleep is Never/unknown.
- **Starts on with the system** (launch at login).
- **Console control**: `alwaysgreen start | stop | toggle | status`.
- No power assertions, no data collected, no network.

## Project layout

- `AlwaysGreenCore` - pure logic (engine, interval policy, CLI parsing, state), fully unit-tested.
- `AlwaysGreenApp` - the menu-bar app (AppKit `NSStatusItem` + SwiftUI panel).
- `alwaysgreen` - the CLI, drives the running app over `DistributedNotificationCenter`.

## Build & run

```sh
swift make-icon.swift && iconutil -c icns AppIcon.iconset -o AppIcon.icns   # once, optional icon
./build.sh
open "./Always Green.app"
./alwaysgreen status
```

Requires macOS 14+ and Xcode. On first run, grant Accessibility - the app guides you there and
never shows a raw system prompt; once enabled it auto-starts.

## CLI

```sh
./alwaysgreen start | stop | toggle | status
ln -s "$PWD/alwaysgreen" /usr/local/bin/alwaysgreen   # put it on PATH
```

The CLI controls the same app (launching it if needed), so only the app needs the Accessibility
grant - not your terminal.

## Tests & coverage

```sh
swift test
./coverage.sh     # gates AlwaysGreenCore line coverage at >=90%
```

## Before shipping

- `Sources/AlwaysGreenApp/SystemActions.swift` - Buy-Me-a-Coffee handle.
- `Info.plist` and `Sources/AlwaysGreenCore/Config.swift` - bundle id + IPC name (keep in sync).

## Distribution

The App Store sandbox blocks the synthetic input this relies on, so ship as a direct download.

```sh
export DEVELOPER_ID="Developer ID Application: Your Name (TEAMID)"
export NOTARY_PROFILE="your-notarytool-profile"
./dist.sh          # build -> Developer ID sign -> notarize -> staple
```

Requires the Apple Developer Program ($99/yr; also makes the login item reliable).

## Install via Homebrew

The cask (`homebrew/always-green.rb`) installs `Always Green.app` and links the bundled
`alwaysgreen` CLI onto your PATH. Once a signed release is published:

```sh
brew tap kofcio94/tap
brew install --cask always-green
```

Publishing the tap:

1. Cut a GitHub release and upload the notarized zip that `./dist.sh` produces as
   `AlwaysGreen-<version>.zip`.
2. Get its digest: `shasum -a 256 AlwaysGreen-<version>.zip`.
3. Create a repo named `homebrew-tap`, drop `homebrew/always-green.rb` under `Casks/`, and set
   `version`, `url`, and the real `sha256`.

Test the cask locally before publishing:

```sh
brew install --cask ./homebrew/always-green.rb
```

A smooth cask install needs a notarized build (`./dist.sh`); an ad-hoc build is still gated by
Gatekeeper on first launch.

## Privacy

No data collected, no network, no analytics. Settings are stored locally. Accessibility is used
only to move the cursor.
