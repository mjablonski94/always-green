#!/bin/bash

# Run with "bash ops.sh" in a logged-in macOS desktop session.
if [[ $OSTYPE != darwin* ]]; then
    printf '%s\n' 'Cursor movement requires macOS.' >&2
    exit 1
fi

move_mouse() {
    # Bash schedules the nudges. The system bridge calls the macOS cursor API.
    /usr/bin/osascript -l JavaScript <<'JXA'
ObjC.import('CoreGraphics');
ObjC.bindFunction('CGPreflightPostEventAccess', ['bool', []]);
if (!$.CGPreflightPostEventAccess()) {
    throw new Error('Allow your terminal in System Settings > Privacy & Security > Accessibility, then run the script again.');
}

function cursorPosition() {
    const snapshot = $.CGEventCreate(null);
    if (!snapshot) throw new Error('macOS could not read the cursor position.');
    return $.CGEventGetLocation(snapshot);
}

function moveTo(point) {
    const event = $.CGEventCreateMouseEvent(null, $.kCGEventMouseMoved, point, $.kCGMouseButtonLeft);
    if (!event) throw new Error('macOS could not create a mouse movement event.');
    $.CGEventPost($.kCGHIDEventTap, event);
}

const start = cursorPosition();
const display = Ref();
const count = Ref();
if ($.CGGetDisplaysWithPoint(start, 1, display, count) !== 0 || count[0] === 0) {
    throw new Error('Run the script from a logged-in macOS desktop with an active display.');
}
const bounds = $.CGDisplayBounds(display[0]);
const centerX = bounds.origin.x + bounds.size.width / 2;
const target = { x: start.x + (start.x < centerX ? 8 : -8), y: start.y };
moveTo(target);
delay(0.25);

// Leave the pointer alone if the user moved it during the nudge.
const current = cursorPosition();
if (current.x === target.x && current.y === target.y) moveTo(start);
JXA
}

sleep_pid=
stop() {
    if [[ -n $sleep_pid ]]; then
        kill "$sleep_pid" 2>/dev/null
    fi
    exit 0
}
trap stop INT TERM HUP

printf '%s\n' 'Press Ctrl+C to stop.'
while :; do
    move_mouse || exit 1
    /bin/sleep 30 &
    sleep_pid=$!
    wait "$sleep_pid" || exit 1
    sleep_pid=
done
