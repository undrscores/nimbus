#!/bin/sh
# Nimbus setup for openSUSE Tumbleweed.
#
# Installs the packages Nimbus needs, builds the two libraries that are not packaged
# (libcava, M3Shapes) into ~/.local, installs the fonts and the helper CLI, and builds the plugin.
# Every step that needs sudo or downloads/builds third-party code asks first.
set -e

root="$(cd "$(dirname "$0")/.." && pwd)"
deps="$HOME/Projects/deps"
prefix="$HOME/.local"
fontdir="${XDG_DATA_HOME:-$HOME/.local/share}/fonts"

ask() {
    printf '%s [y/N] ' "$1"
    read -r reply
    [ "$reply" = y ] || [ "$reply" = Y ]
}

# ---------------------------------------------------------------- packages
packages="git cmake ninja gcc-c++ meson pkgconf-pkg-config
    quickshell niri
    qt6-base-devel qt6-declarative-devel qt6-shadertools-devel qt6-multimedia-devel qt6-sql-devel
    qt6-multimedia-imports qt6-imageformats
    libqalculate-devel pipewire-devel aubio-devel libsensors4-devel fftw3-devel libiniparser-devel
    python313-Pillow gpu-screen-recorder wf-recorder slurp swappy wl-clipboard libnotify-tools
    ddcutil brightnessctl power-profiles-daemon playerctl libxml2-tools fish
    nerdfonts-symbolsonly-fonts papirus-icon-theme"

if ask "Install packages with sudo zypper?"; then
    # shellcheck disable=SC2086
    sudo zypper in $packages
fi

# ------------------------------------------------------------ libcava (meson)
if ! pkg-config --exists libcava 2>/dev/null && [ ! -f "$prefix/lib64/pkgconfig/libcava.pc" ]; then
    if ask "Build libcava (github.com/LukashonakV/cava) into $prefix?"; then
        mkdir -p "$deps"
        [ -d "$deps/libcava" ] || git clone --depth 1 https://github.com/LukashonakV/cava "$deps/libcava"
        if [ -d "$deps/libcava/build" ]; then
            meson setup --reconfigure "$deps/libcava/build" "$deps/libcava" --prefix="$prefix" --buildtype=release
        else
            meson setup "$deps/libcava/build" "$deps/libcava" --prefix="$prefix" --buildtype=release
        fi
        ninja -C "$deps/libcava/build"
        meson install -C "$deps/libcava/build"
    fi
fi

# ------------------------------------------------------------ M3Shapes (cmake)
if [ ! -f "$prefix/lib64/qt6/qml/M3Shapes/qmldir" ]; then
    if ask "Build M3Shapes (github.com/soramanew/m3shapes) into $prefix?"; then
        mkdir -p "$deps"
        [ -d "$deps/m3shapes" ] || git clone --depth 1 https://github.com/soramanew/m3shapes "$deps/m3shapes"
        cmake -S "$deps/m3shapes" -B "$deps/m3shapes/build" -G Ninja \
            -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX="$prefix"
        cmake --build "$deps/m3shapes/build"
        cmake --install "$deps/m3shapes/build"
    fi
fi

# ---------------------------------------------------------------------- fonts
if ! fc-list | grep -qi "material symbols rounded" || ! fc-list | grep -qi "rubik"; then
    if ask "Download Material Symbols Rounded and Rubik fonts (github.com/google) to $fontdir?"; then
        mkdir -p "$fontdir" "$deps/fonts-dl"
        curl -fsSL -o "$deps/fonts-dl/MaterialSymbolsRounded.ttf" \
            'https://github.com/google/material-design-icons/raw/master/variablefont/MaterialSymbolsRounded%5BFILL%2CGRAD%2Copsz%2Cwght%5D.ttf'
        curl -fsSL -o "$deps/fonts-dl/Rubik.ttf" \
            'https://github.com/google/fonts/raw/main/ofl/rubik/Rubik%5Bwght%5D.ttf'
        cp "$deps/fonts-dl/MaterialSymbolsRounded.ttf" "$deps/fonts-dl/Rubik.ttf" "$fontdir/"
        fc-cache -f "$fontdir"
    fi
fi

# The shell's default UI font is Google Sans Flex and its monospace font is CaskaydiaCove NF; without them it falls
# back to Noto Sans / Source Code Pro.
if ! fc-list | grep -qi "google sans flex" || ! fc-list | grep -qi "caskaydiacove"; then
    if ask "Download Google Sans Flex and CaskaydiaCove Nerd Font (github.com/google, ryanoasis/nerd-fonts) to $fontdir?"; then
        mkdir -p "$fontdir" "$deps/fonts-dl/cascadia"
        curl -fsSL -o "$deps/fonts-dl/GoogleSansFlex.ttf" \
            'https://github.com/google/fonts/raw/main/ofl/googlesansflex/GoogleSansFlex%5BROND%2Copsz%2Cslnt%2Cwdth%2Cwght%5D.ttf'
        curl -fsSL -o "$deps/fonts-dl/CascadiaCode.tar.xz" \
            'https://github.com/ryanoasis/nerd-fonts/releases/latest/download/CascadiaCode.tar.xz'
        tar -xJf "$deps/fonts-dl/CascadiaCode.tar.xz" -C "$deps/fonts-dl/cascadia"
        cp "$deps/fonts-dl/GoogleSansFlex.ttf" "$fontdir/"
        cp "$deps/fonts-dl"/cascadia/CaskaydiaCoveNerdFont-*.ttf "$fontdir/"
        fc-cache -f "$fontdir"
    fi
fi

# ------------------------------------------------------------------ helper CLI
if ! command -v nimbus >/dev/null 2>&1; then
    if ask "Install the helper CLI (creates a venv and installs materialyoucolor from PyPI)?"; then
        "$root/scripts/install-cli.sh"
    fi
fi

# ----------------------------------------------------------------- plugin build
if ask "Build the Nimbus plugin in $root/build?"; then
    export PKG_CONFIG_PATH="$prefix/lib64/pkgconfig${PKG_CONFIG_PATH:+:$PKG_CONFIG_PATH}"
    # libcava's .pc exports -I.../include/cava but the sources include <cava/...>
    export CPLUS_INCLUDE_PATH="$prefix/include${CPLUS_INCLUDE_PATH:+:$CPLUS_INCLUDE_PATH}"
    cmake -S "$root" -B "$root/build" -G Ninja -DCMAKE_BUILD_TYPE=Release -DVERSION=0.0.1
    cmake --build "$root/build"
fi

cat <<EOF

Done. Next:
  1. Add the autostart line and binds from docs/niri-config.kdl to ~/.config/niri/config.kdl
     (replace /path/to/nimbus with $root).
  2. Screen recording: portal capture needs no setup. For KMS capture, gpu-screen-recorder needs
       sudo setcap cap_sys_admin+ep "\$(command -v gsr-kms-server)"
     (broad capability, and a package update resets it. If it cannot encode, e.g. NVENC/driver mismatch,
     Nimbus falls back to software encoding with wf-recorder)
  3. Start it now with:       $root/scripts/niri-start.sh
EOF
