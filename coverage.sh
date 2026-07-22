#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")"

THRESHOLD=90

swift test --enable-code-coverage >/dev/null 2>&1
BIN="$(swift build --show-bin-path)"
XCTEST="$(find "$BIN" -maxdepth 1 -name '*.xctest' | head -1)"
EXEC="$XCTEST/Contents/MacOS/$(basename "$XCTEST" .xctest)"
PROF="$BIN/codecov/default.profdata"

xcrun llvm-cov report "$EXEC" -instr-profile "$PROF" Sources/AlwaysGreenCore

PCT="$(xcrun llvm-cov report "$EXEC" -instr-profile "$PROF" Sources/AlwaysGreenCore \
    | awk '/^TOTAL/{ c=0; for (i=1;i<=NF;i++){ if ($i ~ /%$/){ c++; if (c==3){ sub(/%/,"",$i); print $i } } } }')"

echo
echo "Core line coverage: ${PCT}% (threshold ${THRESHOLD}%)"
if awk "BEGIN{ exit !(${PCT} >= ${THRESHOLD}) }"; then
    echo "PASS"
else
    echo "FAIL: Core line coverage below ${THRESHOLD}%"
    exit 1
fi
