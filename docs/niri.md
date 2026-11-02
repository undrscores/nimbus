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
