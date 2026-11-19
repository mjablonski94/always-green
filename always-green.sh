#!/bin/bash

# Always Green — offline macOS sleep prevention
# Uses only commands included with macOS; no downloads or installation.
# Run: bash always-green.sh
# Stop: Ctrl+C
#
# This prevents idle sleep, but does not simulate keyboard/mouse input
# or guarantee an Available status in Microsoft Teams or Slack.

trap 'exit 0' INT TERM HUP

# Preferred: prevent display and system idle sleep.
if [[ -x /usr/bin/caffeinate ]]; then
    /usr/bin/caffeinate -di >/dev/null 2>&1
    status=$?

    # Ctrl+C stops the script rather than activating the fallback.
    [[ $status -eq 130 ]] && exit 0
fi

# Fallback: prevent system idle sleep (display may still sleep).
if [[ -x /usr/bin/pmset ]]; then
    exec /usr/bin/pmset noidle >/dev/null 2>&1
fi

echo "No supported macOS sleep-prevention method found." >&2
exit 1
