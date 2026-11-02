<h1 align=center>Nimbus</h1>

<p align=center>A Quickshell desktop shell for <a href="https://github.com/YaLTeR/niri">niri</a>, ported from <a href="https://github.com/caelestia-dots/shell">Caelestia</a>.</p>

Nimbus is a fork of the Caelestia shell (bar, dashboard, launcher, sidebar, session menu, lock screen, notifications,
OSD, area picker, wallpapers and Material You colours) rebuilt to run on **niri** instead of Hyprland. It talks to niri
over its IPC socket and has no Hyprland dependency. Colour schemes, widgets and the configuration format are unchanged,
so the upstream look carries over.

> [!NOTE]
> Nimbus is an unofficial fork and is not affiliated with the Caelestia project. All credit for the shell's design and
> code goes to [@soramanew](https://github.com/soramanew) and the Caelestia contributors; see [Credits](#credits).

## What changed from upstream

| Area | Caelestia (Hyprland) | Nimbus (niri) |
| --- | --- | --- |
| Compositor state | `Quickshell.Hyprland` + C++ helpers | `services/Niri.qml` over `$NIRI_SOCKET` |
| Keybinds | Hyprland global shortcuts | `qs ipc call shortcut trigger <name>` bound in niri's `config.kdl` |
| Click-outside dismissal | `HyprlandFocusGrab` | exclusive layer-shell keyboard focus + click catcher |
| Workspaces | numbered, plus special workspaces | niri's per-output workspaces; special workspaces removed |
| Caps/num lock | Hyprland device info | keyboard LEDs in `/sys/class/leds` |
| Fullscreen detection | Hyprland client flag | window size vs output size |
| `caelestia` CLI | upstream CLI | trimmed fork in [`cli/`](cli): wallpaper, scheme, theme, record |

Known limitations: the area picker cannot snap to windows (niri reports no window positions), game mode only affects the
shell and there is no window pin button. App theming covers Alacritty, niri, GTK, Qt/KDE and Zed only; see [docs/niri.md](docs/niri.md#app-theming).
Details are in [docs/niri.md](docs/niri.md).

## Install

Nimbus is built from source. On openSUSE Tumbleweed the whole process is scripted:

```sh
git clone https://github.com/undrscores/nimbus ~/Projects/nimbus
cd ~/Projects/nimbus
scripts/setup-opensuse.sh      # packages, libcava, M3Shapes, fonts, CLI, plugin build (asks before sudo)
```

Other distributions need the same pieces by hand:

- `quickshell` (a recent release), `niri`, Qt 6 (base, declarative, shadertools, multimedia, imageformats), CMake, Ninja, g++
- [`libcava`](https://github.com/LukashonakV/cava) and [`M3Shapes`](https://github.com/soramanew/m3shapes) (neither is packaged on most distros)
- `libpipewire`, `aubio`, `libqalculate`, `lm_sensors`
- fonts: Material Symbols Rounded, Rubik, a Nerd Font symbols font
- runtime tools: `ddcutil`, `brightnessctl`, `swappy`, `wl-clipboard`, `slurp`, `gpu-screen-recorder`, `libnotify`, `playerctl`,
  `power-profiles-daemon`, `networkmanager`
- the `nimbus` helper CLI: `scripts/install-cli.sh` (needs `python3-Pillow`; `materialyoucolor` comes from PyPI)

Build the plugin manually with:

```sh
cmake -S . -B build -G Ninja -DCMAKE_BUILD_TYPE=Release -DVERSION=0.0.1
cmake --build build
```

## Run it

Add to niri's `config.kdl` (a full example is in [docs/niri-config.kdl](docs/niri-config.kdl)):

```kdl
spawn-at-startup "/path/to/nimbus/scripts/niri-start.sh"
```

then bind the shortcuts you want:

```kdl
Mod+Space { spawn "qs" "-p" "/path/to/nimbus/shell.qml" "ipc" "call" "shortcut" "trigger" "launcher"; }
```

`qs -p /path/to/nimbus/shell.qml ipc call shortcut list` prints every shortcut name. The default binds in the example are:

| Key | Action |
| --- | --- |
| `Mod+Space` | launcher |
| `Mod+A` | dashboard |
| `Mod+N` | sidebar |
| `Mod+X` | session menu |
| `Mod+Y` | utilities |
| `Mod+Ctrl+Comma` | settings |
| `Mod+Shift+D` | do not disturb |
| `Mod+Ctrl+N` | clear notifications |
| `Mod+Shift+S` / `Mod+Ctrl+S` | screenshot picker / to clipboard |
| `Super+Alt+L` | lock |

## Configuration

Options live in `~/.config/caelestia/shell.json` and are documented in [docs/configuration.md](docs/configuration.md).
Per-monitor overrides go in `~/.config/caelestia/monitors/<output>/shell.json`; list outputs with
`niri msg --json outputs | jq -r 'keys[]'`.

## Troubleshooting

- **Icons show as words** (`chevron_left`, `memory`): the Material Symbols Rounded font is missing; run `fc-list | grep -i "material symbols"`.
- **Shell crashes at startup with `module "…" is not installed`**: a Qt module or `M3Shapes` is missing from `QML_IMPORT_PATH`; use `scripts/niri-start.sh`.
- **Screen recording does nothing**: `gpu-screen-recorder` needs `sudo setcap cap_sys_admin+ep /usr/bin/gsr-kms-server`, or portal capture.
- **Logs**: `qs -p /path/to/nimbus/shell.qml log`.

## Credits

Nimbus is built on the [Caelestia shell](https://github.com/caelestia-dots/shell) by [@soramanew](https://github.com/soramanew)
and contributors, and its `cli/` directory is derived from [caelestia-dots/cli](https://github.com/caelestia-dots/cli).
Both are GPL-3.0, as is Nimbus. Thanks also to [Quickshell](https://quickshell.outfoxxed.me) by
[@outfoxxed](https://github.com/outfoxxed), to [niri](https://github.com/YaLTeR/niri), and to the configs Caelestia itself
drew on, [end-4/dots-hyprland](https://github.com/end-4/dots-hyprland) and [Axenide/Ax-Shell](https://github.com/Axenide/Ax-Shell).

## License

GPL-3.0, see [LICENSE](LICENSE).
