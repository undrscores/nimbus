#!/bin/sh
# Graphical login screen for niri on openSUSE: greetd + ReGreet (GTK4) running inside the cage kiosk compositor.
# Replaces the text console login (or the tuigreet TUI) and lists the Wayland sessions, i.e. "Niri".
#
#   sudo sh scripts/setup-login.sh
#
# The new login screen only starts on the next boot; nothing is restarted now. If it ever misbehaves, switch to a
# text console with Ctrl+Alt+F2, log in and run:
#   sudo systemctl disable greetd && sudo systemctl set-default multi-user.target
# The previous /etc/greetd/config.toml is kept as config.toml.bak-pre-nimbus.
set -e

if [ "$(id -u)" -ne 0 ]; then
    echo "Run this as root: sudo sh $0" >&2
    exit 1
fi

user="${SUDO_USER:-}"
home=""
[ -n "$user" ] && home="$(getent passwd "$user" | cut -d: -f6)"

echo ":: Installing greetd, regreet and cage"
# zypper exits with 100-107 for informational results (e.g. 107: a package script warned) even when the install worked,
# which must not abort the setup.
rc=0
zypper -n install greetd regreet cage || rc=$?
if [ "$rc" -ne 0 ] && { [ "$rc" -lt 100 ] || [ "$rc" -gt 107 ]; }; then
    echo "zypper failed with exit code $rc" >&2
    exit "$rc"
fi
[ "$rc" -ne 0 ] && echo ":: zypper reported code $rc (informational), continuing"
for bin in greetd regreet cage; do
    command -v "$bin" >/dev/null 2>&1 || { echo "$bin is not installed" >&2; exit 1; }
done

cfg=/etc/greetd/config.toml
if [ -f "$cfg" ] && [ ! -f "$cfg.bak-pre-nimbus" ]; then
    cp -a "$cfg" "$cfg.bak-pre-nimbus"
fi

echo ":: Writing $cfg"
cat > "$cfg" <<'EOF'
[terminal]
vt = 1

[default_session]
command = "cage -s -m last -- regreet"
user = "greeter"
EOF

# The greeter runs as the `greeter` user, so it cannot read files in your home: copy the wallpaper and the fonts
# somewhere it can.
bg=""
if [ -n "$home" ] && [ -e "$home/.local/state/caelestia/wallpaper/current" ]; then
    wall="$(readlink -f "$home/.local/state/caelestia/wallpaper/current")"
    # GTK may lack a WebP loader, so store a PNG
    if python3 -c "
import sys
from PIL import Image
Image.open(sys.argv[1]).convert('RGB').save('/etc/greetd/nimbus-background.png')
" "$wall" 2>/dev/null; then
        chmod 644 /etc/greetd/nimbus-background.png
        bg="/etc/greetd/nimbus-background.png"
        echo ":: Using your wallpaper as the login background"
    else
        echo ":: Could not convert the wallpaper (python3-Pillow missing?), using no background"
    fi
fi

font="Sans 12"
if [ -n "$home" ] && ls "$home"/.local/share/fonts/GoogleSansFlex*.ttf >/dev/null 2>&1; then
    mkdir -p /usr/local/share/fonts
    cp "$home"/.local/share/fonts/GoogleSansFlex*.ttf /usr/local/share/fonts/
    fc-cache -f /usr/local/share/fonts
    font="Google Sans Flex 12"
fi

echo ":: Writing /etc/greetd/regreet.toml"
{
    if [ -n "$bg" ]; then
        printf '[background]\npath = "%s"\nfit = "Cover"\n\n' "$bg"
    fi
    printf '[GTK]\napplication_prefer_dark_theme = true\nfont_name = "%s"\n\n' "$font"
    printf '[commands]\nreboot = [ "systemctl", "reboot" ]\npoweroff = [ "systemctl", "poweroff" ]\n'
} > /etc/greetd/regreet.toml

echo ":: Enabling greetd and the graphical target for the next boot"
systemctl enable greetd.service
systemctl set-default graphical.target

echo
echo "Done. Reboot to see the login screen."
