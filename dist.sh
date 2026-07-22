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

./build.sh release

codesign --force --options runtime --timestamp --sign "$DEVELOPER_ID" "$APP/Contents/MacOS/alwaysgreen"
codesign --force --options runtime --timestamp --sign "$DEVELOPER_ID" "$APP/Contents/MacOS/AlwaysGreenApp"
codesign --force --options runtime --timestamp --sign "$DEVELOPER_ID" "$APP"
codesign --verify --deep --strict --verbose=2 "$APP"

ditto -c -k --keepParent "$APP" "$ZIP"
xcrun notarytool submit "$ZIP" --keychain-profile "$NOTARY_PROFILE" --wait
xcrun stapler staple "$APP"

echo "Signed, notarized, stapled: $APP"
