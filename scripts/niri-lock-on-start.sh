#!/bin/sh
# Lock the Caelestia lock screen as soon as the shell is up (replaces the greeter login).
shell="$(cd "$(dirname "$0")/.." && pwd)/shell.qml"
export PATH="$HOME/.local/bin:$PATH"
i=0
while [ "$i" -lt 100 ]; do
    if qs -p "$shell" ipc call lock lock >/dev/null 2>&1; then
        # make sure it actually took
        [ "$(qs -p "$shell" ipc call lock isLocked 2>/dev/null)" = "true" ] && exit 0
    fi
    i=$((i + 1)); sleep 0.2
done
# Never got a confirmed lock. Say so loudly instead of leaving an unlocked session that looks like it worked.
echo "niri-lock-on-start: could not lock the session after 20s (is the shell running?)" >&2
exit 1
