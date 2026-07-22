#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")"

CONFIG="${1:-release}"
APP="Always Green.app"
CONTENTS="$APP/Contents"

echo "Building ($CONFIG)..."
swift build -c "$CONFIG" --product AlwaysGreenApp
swift build -c "$CONFIG" --product alwaysgreen
BIN="$(swift build -c "$CONFIG" --show-bin-path)"

rm -rf "$APP"
mkdir -p "$CONTENTS/MacOS" "$CONTENTS/Resources"
cp "$BIN/AlwaysGreenApp" "$CONTENTS/MacOS/AlwaysGreenApp"
cp "$BIN/alwaysgreen" "$CONTENTS/MacOS/alwaysgreen"
cp Info.plist "$CONTENTS/Info.plist"
[ -f AppIcon.icns ] && cp AppIcon.icns "$CONTENTS/Resources/AppIcon.icns"
cp "$BIN/alwaysgreen" "./alwaysgreen"

if codesign --force --sign - "$APP" >/dev/null 2>&1; then
    echo "Ad-hoc signed."
else
    echo "Warning: ad-hoc codesign failed (the app still runs locally)."
fi

echo "Built ./$APP and ./alwaysgreen (CLI)"
echo "Run:  open \"./$APP\"   |   ./alwaysgreen status"
