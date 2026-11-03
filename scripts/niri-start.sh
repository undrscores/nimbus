#!/bin/sh
# Start the shell from a source checkout built in ./build (see docs/niri.md).
# Libraries installed under ~/.local (libcava, m3shapes) are added to the search paths.
export PATH="$HOME/.local/bin:$PATH"
root="$(cd "$(dirname "$0")/.." && pwd)"
# Both lib64 (openSUSE, Fedora) and lib (Arch, others) are listed; missing directories are harmless.
export QML_IMPORT_PATH="$root/build/qml:$HOME/.local/lib64/qt6/qml:$HOME/.local/lib/qt6/qml${QML_IMPORT_PATH:+:$QML_IMPORT_PATH}"
export LD_LIBRARY_PATH="$HOME/.local/lib64:$HOME/.local/lib:$root/build/lib${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
# Icon theme for Quickshell (no Qt platform theme is configured on a bare niri session).
export QS_ICON_THEME="${QS_ICON_THEME:-breeze}"
exec quickshell -p "$root/shell.qml"
