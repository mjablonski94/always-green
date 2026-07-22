#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")"

# Developer ID signing + notarization for direct distribution.
# Prerequisites (Apple Developer Program):
#   export DEVELOPER_ID="Developer ID Application: Your Name (TEAMID)"
#   export NOTARY_PROFILE="a-notarytool-keychain-profile"   # xcrun notarytool store-credentials
: "${DEVELOPER_ID:?set DEVELOPER_ID}"
: "${NOTARY_PROFILE:?set NOTARY_PROFILE}"

APP="Always Green.app"
ZIP="AlwaysGreen.zip"
STAGE="dist"

./build.sh release

# Sign the app (signing the bundle signs its main executable) and the standalone CLI.
codesign --force --options runtime --timestamp --sign "$DEVELOPER_ID" "$APP"
codesign --force --options runtime --timestamp --sign "$DEVELOPER_ID" "alwaysgreen"
codesign --verify --strict --verbose=2 "$APP"

# Notarize the app, then staple.
ditto -c -k --keepParent "$APP" "notarize.zip"
xcrun notarytool submit "notarize.zip" --keychain-profile "$NOTARY_PROFILE" --wait
xcrun stapler staple "$APP"
rm -f "notarize.zip"

# Release artifact for the Homebrew cask: stapled app + CLI at the archive root.
rm -rf "$STAGE"; mkdir -p "$STAGE"
cp -R "$APP" "$STAGE/"
cp "alwaysgreen" "$STAGE/"
ditto -c -k "$STAGE" "$ZIP"

echo "Signed, notarized, stapled. Release artifact: $ZIP (app + alwaysgreen CLI)"
