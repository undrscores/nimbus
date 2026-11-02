#!/bin/sh
# Install the `nimbus` helper CLI (./cli) into a venv and link it into ~/.local/bin.
# Needs: python313-Pillow (system), network access to PyPI for materialyoucolor + build backend.
set -e
root="$(cd "$(dirname "$0")/.." && pwd)"
data="${XDG_DATA_HOME:-$HOME/.local/share}"
venv="$data/nimbus-cli/venv"
python3 -m venv --system-site-packages "$venv"
"$venv/bin/pip" install --upgrade "$root/cli"
mkdir -p "$HOME/.local/bin"
ln -sf "$venv/bin/nimbus" "$HOME/.local/bin/nimbus"
# Clean up the pre-rename install (the `caelestia` alias and its venv)
if [ -L "$HOME/.local/bin/caelestia" ]; then rm -f "$HOME/.local/bin/caelestia"; fi
rm -rf "$data/caelestia-niri-cli"
echo "installed: $HOME/.local/bin/nimbus"
