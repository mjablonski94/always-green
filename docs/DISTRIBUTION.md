# Distribution

Always Green is distributed as a **direct download**, not via the Mac App Store: the App Store
sandbox blocks the synthetic input the app depends on.

## Why notarization is mandatory

Modern macOS runs two gates:

- **Gatekeeper** rejects apps that are not signed by a known developer ("cannot be checked for
  malware"), with an "Open Anyway" escape hatch.
- **XProtect** scans binaries for malware signatures. An app that synthesizes input
  (`CGEventPost`) and is unsigned/ad-hoc can match a heuristic and get **hard-blocked and moved to
  the Bin**, with no override.

The only reliable way past both is a **Developer ID Application** signature plus **notarization**:
Apple's notary service scans the app and issues a ticket, which you staple to the bundle.
Notarized builds are not flagged.

## Prerequisites

- Apple Developer Program membership.
- A **Developer ID Application** certificate in your keychain (distinct from "Apple Development"
  or "Apple Distribution" certificates - those cannot notarize for outside-the-store distribution
  and, in the case of a development cert, require a provisioning profile just to launch).
- A stored notarytool credential profile:

  ```sh
  xcrun notarytool store-credentials "AlwaysGreenNotary" \
      --apple-id "you@example.com" --team-id "TEAMID" --password "app-specific-password"
  ```

## Release with dist.sh

```sh
export DEVELOPER_ID="Developer ID Application: Your Name (TEAMID)"
export NOTARY_PROFILE="AlwaysGreenNotary"
./dist.sh
```

`dist.sh`:

1. Builds a release via `build.sh`.
2. Signs the app and the standalone `alwaysgreen` CLI with the Developer ID (hardened runtime).
3. Notarizes the app and staples the ticket.
4. Builds a drag-to-install DMG via `make-dmg.sh` (the app, the `alwaysgreen` CLI, and an
   `/Applications` shortcut), then signs, notarizes, and staples the DMG - producing
   `AlwaysGreen-<version>.dmg`, the artifact the download link and the Homebrew cask both use.

To build just the DMG locally (unsigned, for a quick look): `./make-dmg.sh`.

Verify:

```sh
spctl -a -vvv "Always Green.app"                 # accepted, source=Notarized Developer ID
xcrun stapler validate "AlwaysGreen-1.0.dmg"
```

## Local development signing

`build.sh` ad-hoc signs by default so the app launches without a provisioning profile. A real
identity keeps the Accessibility grant across rebuilds but a *development* cert will fail to spawn
(error 163) without a provisioning profile - use a Developer ID for that, or accept re-granting
Accessibility after each ad-hoc rebuild.

## Homebrew tap

The cask is `homebrew/always-green.rb`. To let users `brew install --cask always-green`:

1. Cut a GitHub release on `mjablonski94/always-green` and upload the `AlwaysGreen-<version>.dmg`
   that `dist.sh` produced.
2. Compute the digest: `shasum -a 256 AlwaysGreen-<version>.dmg`.
3. Create a repository named `homebrew-tap` under your account, add the cask under `Casks/`, and
   set `version`, `url`, and the real `sha256` (replace `:no_check`).
4. Users then run:

   ```sh
   brew tap mjablonski94/tap
   brew install --cask always-green
   ```

Updates ship by publishing a new release and bumping the cask; users get them via `brew upgrade`.

Test the cask locally before publishing:

```sh
brew install --cask ./homebrew/always-green.rb
```

## Release checklist

- [ ] Bump `CFBundleShortVersionString`/`CFBundleVersion` in `Info.plist` and `version` in the cask.
- [ ] `./coverage.sh` passes.
- [ ] `./dist.sh` produces a notarized, stapled `AlwaysGreen-<version>.dmg`.
- [ ] `spctl` reports "Notarized Developer ID"; `xcrun stapler validate` passes on the DMG.
- [ ] GitHub release uploaded; cask `url`/`sha256` updated.
