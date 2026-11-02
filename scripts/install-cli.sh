#!/bin/sh
# Install the trimmed `nimbus` helper CLI (./cli) into a venv and link it into ~/.local/bin.
# Needs: python313-Pillow (system), network access to PyPI for materialyoucolor + build backend.
set -e
root="$(cd "$(dirname "$0")/.." && pwd)"
venv="${XDG_DATA_HOME:-$HOME/.local/share}/caelestia-niri-cli/venv"
python3 -m venv --system-site-packages "$venv"
"$venv/bin/pip" install --upgrade "$root/cli"
mkdir -p "$HOME/.local/bin"
ln -sf "$venv/bin/nimbus" "$HOME/.local/bin/nimbus"
ln -sf "$venv/bin/caelestia" "$HOME/.local/bin/caelestia" # backwards-compatible alias
echo "installed: $HOME/.local/bin/nimbus"
