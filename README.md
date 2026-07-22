# Always Green

A tiny macOS menu-bar app that keeps your Mac active and your chat presence "available"
(Microsoft Teams, Slack, and anything else that reads the OS idle timer) by making a 1-pixel
cursor movement on an interval derived from your screen-sleep setting. It ships with a matching
`alwaysgreen` command-line tool that controls the same app.

- Repository: https://github.com/mjablonski94/auto-green
- Platform: macOS 14 (Sonoma) and later
- Language: Swift 6 (SwiftUI + AppKit)

---

## Table of contents

- [Features](#features)
- [How it works](#how-it-works)
- [Install](#install)
- [Permissions](#permissions)
- [Usage](#usage)
- [Configuration](#configuration)
- [Architecture](#architecture)
- [Development](#development)
- [Distribution](#distribution)
- [Troubleshooting](#troubleshooting)
- [Privacy](#privacy)
- [License](#license)

---

## Features

- **Menu-bar only** (no Dock icon). A filled green circle means on, an outlined green ring means off.
- **Left-click** the icon opens the panel; **right-click** toggles on/off instantly.
- **Smart interval**: defaults to half your system screen-sleep time, so a nudge always lands
  before the screen would sleep. Capped to stay under the ~5-minute presence "Away" threshold;
  a screen-sleep over 5 minutes (or "Never") falls back to 30 seconds. Fully adjustable, with a
  one-click **Reset to auto**.
- **Launch at login** (start with the system) via `SMAppService`.
- **Command-line control**: `alwaysgreen start|stop|toggle|status`, plus an optional `green`
  shell function.
- **No power assertions**: the cursor movement alone keeps the screen and system awake, so the
  app never force-pins your Mac.
- **No network, no data collection, no analytics.**

## How it works

Chat clients flip your status to Away after roughly five minutes with no keyboard or mouse
input. They read the operating system's *input-idle* timer. Always Green posts a tiny synthetic
mouse move (`CGEventPost`) at your chosen interval, which resets that timer, so you stay green.

Because that synthetic input also resets the display and system idle timers, the screen stays on
and the Mac stays awake while Always Green is running - no `IOKit` power assertion needed.

The interval is chosen for you from the current power source's screen-sleep timeout (read with
`pmset`): `interval = clamp(screenSleep / 2, 15s, ...)`, and if screen-sleep is longer than five
minutes or set to Never, it uses a safe 30-second default. See
[docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) for the full data flow.

## Install

### Homebrew (once a notarized release is published)

```sh
brew tap mjablonski94/tap
brew install --cask always-green
```

The cask installs `Always Green.app` and links the standalone `alwaysgreen` CLI onto your PATH.
See [docs/DISTRIBUTION.md](docs/DISTRIBUTION.md) for publishing the tap.

### From source

```sh
git clone git@github.com:mjablonski94/auto-green.git
cd auto-green
./build.sh
open "Always Green.app"
```

Requires macOS 14+ and Xcode 16+ (full Xcode, not just the Command Line Tools).

## Permissions

macOS gates synthetic input behind **Accessibility** - this is the one required permission and
there is no way around it (it is exactly the capability the permission exists to control). The
app never force-prompts on launch; instead the panel shows a short notice with three buttons:

1. **Grant access** - triggers the standard macOS request and lists "Always Green" under
   Privacy & Security > Accessibility.
2. Enable "Always Green" in that list.
3. **Re-check** - the panel then enables Start and the app begins running (or wait ~2s; it polls).

## Usage

### Menu bar

| Action | Result |
| --- | --- |
| Left-click icon | Open the control panel |
| Right-click icon | Toggle on/off without opening the panel |
| Filled green circle | Running |
| Outlined green ring | Stopped |

### Command line

```sh
alwaysgreen start     # start (launches the app if needed)
alwaysgreen stop      # stop
alwaysgreen toggle    # flip on/off
alwaysgreen status    # e.g. "always green: on (interval 60s, app running, accessibility granted)"
```

The CLI drives the running app over a local notification, so only the app needs the Accessibility
grant - not your terminal. Put it on PATH with:

```sh
ln -s "$PWD/alwaysgreen" /opt/homebrew/bin/alwaysgreen
```

### Optional `green` shell function

If you prefer the short command, add this to `~/.zshrc` (it delegates to the app):

```zsh
green() {
  local cli; cli="$(command -v alwaysgreen 2>/dev/null)"; [[ -z $cli ]] && cli="$HOME/repo/auto-green/alwaysgreen"
  "$cli" "${1:-status}"
}
```

## Configuration

- **Green check interval**: the stepper (5s-10min). Changing it switches to Manual; the
  "Reset to auto" button returns to the screen-sleep-derived value.
- **Launch at login (start with system)**: registers/unregisters a login item.

Settings persist in `UserDefaults`; the running state is published to
`~/Library/Application Support/Always Green/state.json` for the CLI.

## Architecture

Three Swift Package targets, with the dependency rule pointing inward:

- **`AlwaysGreenCore`** (library) - pure logic and protocols, no UI. The state machine
  (`JiggleEngine`), interval policy, CLI parsing, and persisted state. This is what the tests cover.
- **`AlwaysGreenApp`** (executable) - the menu-bar app: `NSStatusItem`, an `NSPopover` with the
  SwiftUI panel, and the live implementations of Core's protocols.
- **`alwaysgreen`** (executable) - the CLI, a thin shell over Core.

Full details, including a diagram and the dependency-injection seams, are in
[docs/ARCHITECTURE.md](docs/ARCHITECTURE.md).

## Development

```sh
./build.sh            # build + assemble "Always Green.app" and ./alwaysgreen
swift test            # run the unit tests
./coverage.sh         # gate AlwaysGreenCore line coverage at >= 90%
swift make-icon.swift && iconutil -c icns AppIcon.iconset -o AppIcon.icns   # regenerate the icon
```

Conventions, the DI pattern, and how to add a new dependency are in
[docs/DEVELOPMENT.md](docs/DEVELOPMENT.md).

## Distribution

The Mac App Store sandbox blocks the synthetic input this app relies on, so it ships as a direct
download. A build must be **Developer ID signed and notarized** or macOS will block it (see
[Troubleshooting](#troubleshooting)). `./dist.sh` performs sign -> notarize -> staple and produces
the release zip. Full steps: [docs/DISTRIBUTION.md](docs/DISTRIBUTION.md).

## Troubleshooting

- **"Always Green.app was not opened because it contains malware" / moved to Bin.** That is
  macOS's XProtect scanner. Unsigned/ad-hoc builds that synthesize input can trip it. The fix is
  a **notarized** build (`dist.sh`). For local development, launch via `alwaysgreen start` rather
  than double-clicking in Finder.
- **"App can't be opened because Apple cannot check it for malware."** Ordinary Gatekeeper on an
  un-notarized build; right-click > Open, or notarize it.
- **Granted Accessibility but the panel still asks.** Ad-hoc signatures change on every rebuild,
  so macOS drops the grant. Re-grant for the current build (remove any stale "Always Green" entry
  first). A Developer ID build keeps the grant permanently.
- **Interval seems wrong.** It is half your *current* power source's screen-sleep (battery vs AC
  differ), capped under 5 minutes; a long/Never screen-sleep uses 30s. Use the stepper to override.

## Localization

The interface is localized into English, French, Polish, German, Spanish, Portuguese, Italian,
Ukrainian, Simplified Chinese, and Japanese. macOS picks the language from your system settings.
Strings live in `Localizations/<lang>.lproj/Localizable.strings` (English is the source); `build.sh`
copies them into the app bundle. Add a language by copying `en.lproj` and translating the values.
The non-English translations are an initial best-effort pass and welcome native review.

## Privacy

Always Green collects no personal data, makes no network connections, and contains no analytics
or tracking. Settings are stored locally. Accessibility is used only to move the cursor. The
"Buy me a coffee" link opens your browser to a third-party page with its own terms.

## License

No license file is included yet - add one (for example MIT) before publishing binaries or
accepting contributions.
