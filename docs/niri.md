# Running Nimbus on niri

A ready-to-paste config is in [niri-config.kdl](niri-config.kdl). Nimbus talks to niri over its IPC socket (`$NIRI_SOCKET`, see `services/Niri.qml`) and has no Hyprland dependency.

## Autostart

If the shell is installed system-wide (`cmake --install`) and linked as `~/.config/quickshell/caelestia`:

```kdl
spawn-at-startup "qs" "-c" "caelestia"
```

From a source checkout built in `./build`, use the helper script, which also sets the
library/QML paths for anything installed under `~/.local` (libcava, m3shapes):

```kdl
spawn-at-startup "/path/to/nimbus/scripts/niri-start.sh"
```

With a checkout, replace `qs -c caelestia` in the binds below with `qs -p /path/to/nimbus/shell.qml`.

## Keybinds

niri has no global-shortcuts protocol, so shortcuts are triggered through Quickshell IPC:

```sh
qs -c caelestia ipc call shortcut trigger <name>   # press + release
qs -c caelestia ipc call shortcut list             # all names + descriptions
```

Example `binds {}` block:

```kdl
binds {
    Mod+Space        { spawn "qs" "-c" "caelestia" "ipc" "call" "shortcut" "trigger" "launcher"; }
    Mod+D            { spawn "qs" "-c" "caelestia" "ipc" "call" "shortcut" "trigger" "dashboard"; }
    Mod+Shift+E      { spawn "qs" "-c" "caelestia" "ipc" "call" "shortcut" "trigger" "session"; }
    Mod+N            { spawn "qs" "-c" "caelestia" "ipc" "call" "shortcut" "trigger" "sidebar"; }
    Mod+Shift+U      { spawn "qs" "-c" "caelestia" "ipc" "call" "shortcut" "trigger" "utilities"; }
    Mod+Shift+A      { spawn "qs" "-c" "caelestia" "ipc" "call" "shortcut" "trigger" "showall"; }
    Mod+B            { spawn "qs" "-c" "caelestia" "ipc" "call" "shortcut" "trigger" "bar"; }
    Mod+Shift+B      { spawn "qs" "-c" "caelestia" "ipc" "call" "shortcut" "trigger" "autoHide"; }
    Mod+Comma        { spawn "qs" "-c" "caelestia" "ipc" "call" "shortcut" "trigger" "nexus"; }
    Mod+L            { spawn "qs" "-c" "caelestia" "ipc" "call" "shortcut" "trigger" "lock"; }
    Mod+Shift+L      { spawn "qs" "-c" "caelestia" "ipc" "call" "shortcut" "trigger" "unlock"; }
    Mod+Ctrl+N       { spawn "qs" "-c" "caelestia" "ipc" "call" "shortcut" "trigger" "clearNotifs"; }
    Mod+Alt+N        { spawn "qs" "-c" "caelestia" "ipc" "call" "shortcut" "trigger" "toggleDnd"; }

    Print            { spawn "qs" "-c" "caelestia" "ipc" "call" "shortcut" "trigger" "screenshot"; }
    Shift+Print      { spawn "qs" "-c" "caelestia" "ipc" "call" "shortcut" "trigger" "screenshotFreeze"; }
    Ctrl+Print       { spawn "qs" "-c" "caelestia" "ipc" "call" "shortcut" "trigger" "screenshotClip"; }
    Ctrl+Shift+Print { spawn "qs" "-c" "caelestia" "ipc" "call" "shortcut" "trigger" "screenshotFreezeClip"; }

    XF86MonBrightnessUp   allow-when-locked=true { spawn "qs" "-c" "caelestia" "ipc" "call" "shortcut" "trigger" "brightnessUp"; }
    XF86MonBrightnessDown allow-when-locked=true { spawn "qs" "-c" "caelestia" "ipc" "call" "shortcut" "trigger" "brightnessDown"; }
    XF86AudioPlay  allow-when-locked=true { spawn "qs" "-c" "caelestia" "ipc" "call" "shortcut" "trigger" "mediaToggle"; }
    XF86AudioPrev  allow-when-locked=true { spawn "qs" "-c" "caelestia" "ipc" "call" "shortcut" "trigger" "mediaPrev"; }
    XF86AudioNext  allow-when-locked=true { spawn "qs" "-c" "caelestia" "ipc" "call" "shortcut" "trigger" "mediaNext"; }
    XF86AudioStop  allow-when-locked=true { spawn "qs" "-c" "caelestia" "ipc" "call" "shortcut" "trigger" "mediaStop"; }
}
```

`launcherInterrupt` is fired internally for the "any other key closes/forwards" behaviour; bind it only if you used it before.

## Blur / shadows

Hyprland's runtime layer rules are gone. For background blur behind the shell, add a static rule:

```kdl
layer-rule {
    match namespace="^caelestia-"
    // niri blur/shadow options go here, see the niri wiki
}
```

## Known differences from the Hyprland version

- No special (scratchpad) workspaces; the workspace indicator shows niri's per-output workspaces by index.
- Caps/num lock state is read from `/sys/class/leds` (niri doesn't expose it).
- Click-outside dismissal uses layer-shell keyboard focus (`components/misc/FocusGrab.qml`), as niri has no focus-grab protocol.
- Fullscreen detection depends on niri exposing it in window IPC; otherwise treated as "not fullscreen".
- Window info: no pin button; position/size come from niri's window layout info.
- Area picker: only tiled windows with a reported on-screen position can be snapped to.
- Game mode only affects the shell (compositor options can't be changed at runtime in niri).

## Auto-hide mode

Permanent on-screen elements can burn in on OLED panels. Auto-hide mode hides all of them: the bar, the screen border and
its shadow, the desktop clock and the audio visualiser. Windows reclaim the space the bar and border reserved, and
nothing is drawn on screen until you ask for it.

- Toggle at runtime: `qs -c caelestia ipc call shortcut trigger autoHide` (bound to `Mod+Shift+B` in the example above).
- Enable at startup: set `general.autoHide` to `true` in the config.
- Bring the bar back temporarily by pushing the pointer against the left edge (it hides again when the pointer moves
  away), or with the `bar` shortcut. In auto-hide mode the bar only overlays windows and never reserves space.
- Dashboard, launcher, sidebar, session menu, utilities and OSD keep working: they slide in from their screen edge
  on hover, drag or keybind exactly as before.

## App theming

Setting a wallpaper with a `dynamic` scheme regenerates the Material You palette, and `caelestia` applies it to other
apps at the same time (`nimbus wallpaper`, `nimbus scheme set` and `nimbus theme apply` all do this):

| App | What is written | How it updates |
| --- | --- | --- |
| Alacritty | `~/.local/state/caelestia/theme/alacritty.toml`, imported by `alacritty.toml` | live reload |
| niri | `~/.local/state/caelestia/theme/niri.kdl` (focus ring and border colours), `include`d last in `config.kdl` | niri reloads included files |
| GTK 3/4 | `~/.config/gtk-{3,4}.0/gtk.css` (named colours) and `color-scheme` via gsettings | on app start |
| Qt/KDE (Dolphin…) | `~/.local/share/color-schemes/Caelestia.colors`, merged into `~/.config/kdeglobals`, plus a palette-changed D-Bus signal | running KDE apps update live |
| Zed | `~/.config/zed/themes/caelestia.json`, selected in `settings.json` | live |

```sh
nimbus theme setup           # once: wires alacritty.toml, niri's config.kdl and Zed's settings.json
nimbus scheme set -n dynamic # derive colours from the wallpaper (other schemes are themed too)
nimbus theme apply           # re-apply the current scheme without changing it
```

`theme setup` backs up niri's config to `config.kdl.bak-pre-theming` and refuses to edit an `alacritty.toml` or Zed
`settings.json` that already exists (it prints the line to add instead). `gtk.css` files that Nimbus did not write are
left alone.

Turn targets off in `~/.config/caelestia/cli.json`:

```json
{ "theme": { "alacritty": true, "niri": true, "gtk": true, "qt": true, "zed": false } }
```

Templates live in [`cli/src/caelestia/data/templates`](../cli/src/caelestia/data/templates). Copy one to
`~/.config/caelestia/templates/` to override it. `{{name}}` is a scheme colour as `rrggbb`, `{{name.rgb}}` is `r,g,b`
and `{{mode}}` is `dark` or `light`.

### Qt apps (qBittorrent, OBS…)

Qt apps only pick up a theme through a platform theme plugin, which a plain niri session does not load. The simplest
route needs no extra packages: install `qt6-platformtheme-gtk3` (usually already present) and start the session with
`QT_QPA_PLATFORMTHEME=gtk3`, e.g. in niri's `config.kdl` (log out and back in once):

```kdl
environment {
    QT_QPA_PLATFORMTHEME "gtk3"
}
```

Qt apps then follow the generated `gtk.css`, so the `qt` target is not needed (`"qt": false` in `cli.json`). Colours are
less exact than a dedicated Qt palette.

The `qt` target is for the KDE platform theme instead: it writes `~/.config/kdeglobals`, which Qt reads through
`plasma6-integration-plugin` with `QT_QPA_PLATFORMTHEME=kde`. That plugin pulls in `xdg-desktop-portal-kde6` and
`plasma6-workspace`, and a KDE portal competes with the GTK/GNOME ones, so it is only worth it on a KDE-flavoured setup.

## Login screen

A bare niri install boots to a text console. `scripts/setup-login.sh` (run it with `sudo`) installs greetd with the
ReGreet GTK greeter inside the `cage` kiosk compositor, uses your wallpaper as the background and the Nimbus UI font,
and lists the Niri session. It only takes effect on the next boot and keeps the old `/etc/greetd/config.toml` as
`config.toml.bak-pre-nimbus`. To go back to the text console: `sudo systemctl disable greetd && sudo systemctl
set-default multi-user.target` (Ctrl+Alt+F2 gives you a text console if the greeter ever fails).

## App opacity

Alacritty, GTK apps (Thunar, …) and Zed are made translucent by `nimbus theme apply`. Set the opacity with the
**App opacity** slider on the Nexus "Wallpaper & style" page, with `appearance.appOpacity` in `shell.json`, or per run
with `nimbus theme apply --opacity 0.85`. niri blurs what is behind them (see the `background-effect` window rule in
your `config.kdl`). Apps with their own theming, such as Brave, stay opaque.

Add the `window-rule` from [niri-config.kdl](niri-config.kdl): its `draw-border-with-background false` stops niri
painting a solid focus-ring block behind the focused window, which otherwise makes translucent windows look opaque
while focused. GTK3 apps ignore the named colours in `gtk.css`, so `nimbus theme apply` also writes explicit widget
rules for them (`templates/gtk3.css`).

## Icons

Adwaita's icon theme lacks many app icons. If Papirus is installed (`sudo zypper in papirus-icon-theme`),
`nimbus theme apply` selects `Papirus-Dark` (or `Papirus` in light mode) for GTK apps.
