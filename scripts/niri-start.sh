#!/bin/sh
# Start the shell from a source checkout built in ./build (see docs/niri.md).
# Libraries installed under ~/.local (libcava, m3shapes) are added to the search paths.
root="$(cd "$(dirname "$0")/.." && pwd)"
export QML_IMPORT_PATH="$root/build/qml:$HOME/.local/lib64/qt6/qml${QML_IMPORT_PATH:+:$QML_IMPORT_PATH}"
export LD_LIBRARY_PATH="$HOME/.local/lib64:$root/build/lib${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
exec quickshell -p "$root/shell.qml"
