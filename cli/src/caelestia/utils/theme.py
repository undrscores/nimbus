"""Apply the current colour scheme to other apps.

Each target renders a template from `data/templates/` (overridable by a file of the same name in
`~/.config/caelestia/templates/`) and writes it where the app reads it. Targets are independent: an error in one is
logged and does not stop the others. Disable a target in `~/.config/caelestia/cli.json`:

    { "theme": { "alacritty": false, "niri": true, "gtk": true, "qt": true, "zed": true } }

Template placeholders: `{{name}}` is a scheme colour as `rrggbb`, `{{name.rgb}}` is `r,g,b` (decimal), `{{mode}}` is
`dark`/`light` and `{{appearance}}` is the same, for apps that call it that. `{{opacity}}` is the window opacity
(`0.9`) and `{{opacity_hex}}` the same as a two-digit hex alpha (`e6`). The opacity comes from `--opacity`, else the
"App opacity" slider (`appearance.appOpacity` in shell.json), else `theme.opacity` in cli.json.

Files the user owns (alacritty.toml, niri's config.kdl, Zed's settings.json) are only touched by `setup()`
(`nimbus theme setup`), which wires them to the generated files once.
"""

import json
import re
import shutil
import subprocess
from pathlib import Path

from caelestia.utils.io import error, log, log_exception, warn
from caelestia.utils.paths import (
    atomic_write,
    c_config_dir,
    config_dir,
    data_dir,
    get_config,
    templates_dir,
    theme_dir,
    user_templates_dir,
)

GTK_MARKER = "/* caelestia-managed */"
_PLACEHOLDER = re.compile(r"\{\{\s*([A-Za-z0-9_]+)(?:\.(rgb))?\s*\}\}")


_opacity_override: float | None = None


def set_opacity_override(opacity: float | None) -> None:
    global _opacity_override
    _opacity_override = opacity


def _shell_opacity() -> float | None:
    """The slider in the Nimbus settings stores the opacity in the shell config."""
    try:
        return json.loads((c_config_dir / "shell.json").read_text())["appearance"]["appOpacity"]
    except (OSError, ValueError, KeyError, TypeError):
        return None


def get_opacity() -> float:
    """Window opacity for themed apps: --opacity, then the shell config, then cli.json, then 0.9."""
    value = _opacity_override
    if value is None:
        value = _shell_opacity()
    if value is None:
        value = get_config().get("theme", {}).get("opacity", 0.9)
    try:
        return min(1.0, max(0.0, float(value)))
    except (TypeError, ValueError):
        warn("opacity must be a number between 0 and 1, using 0.9")
        return 0.9


def render(template: str, colours: dict[str, str], mode: str) -> str:
    opacity = get_opacity()

    def sub(m: re.Match[str]) -> str:
        name, fmt = m.group(1), m.group(2)
        if name in ("mode", "appearance") and fmt is None:
            return mode
        if name == "opacity" and fmt is None:
            return f"{opacity:g}"
        if name == "opacity_hex" and fmt is None:
            return f"{round(opacity * 255):02x}"
        hexa = colours.get(name)
        if hexa is None:
            raise KeyError(f"scheme has no colour '{name}'")
        if fmt == "rgb":
            return f"{int(hexa[0:2], 16)},{int(hexa[2:4], 16)},{int(hexa[4:6], 16)}"
        return hexa

    return _PLACEHOLDER.sub(sub, template)


def render_file(name: str, colours: dict[str, str], mode: str) -> str:
    path = user_templates_dir / name
    if not path.is_file():
        path = templates_dir / name
    return render(path.read_text(), colours, mode)


def _enabled(target: str) -> bool:
    return bool(get_config().get("theme", {}).get(target, True))


def _write_if_changed(path: Path, content: str) -> bool:
    """Write atomically, skipping identical content so file watchers don't reload for nothing."""
    try:
        if path.read_text() == content:
            return False
    except FileNotFoundError:
        pass
    atomic_write(path, content)
    return True


@log_exception
def apply_alacritty(colours: dict[str, str], mode: str) -> None:
    _write_if_changed(theme_dir / "alacritty.toml", render_file("alacritty.toml", colours, mode))


@log_exception
def apply_niri(colours: dict[str, str], mode: str) -> None:
    _write_if_changed(theme_dir / "niri.kdl", render_file("niri.kdl", colours, mode))


@log_exception
def apply_gtk(colours: dict[str, str], mode: str) -> None:
    css = f"{GTK_MARKER}\n" + render_file("gtk.css", colours, mode)
    for ver in ("gtk-3.0", "gtk-4.0"):
        path = config_dir / ver / "gtk.css"
        if path.exists() and not path.read_text().startswith(GTK_MARKER):
            warn(f"{path} is not managed by caelestia, leaving it alone")
            continue
        _write_if_changed(path, css)

    if shutil.which("gsettings"):
        scheme = "prefer-dark" if mode == "dark" else "prefer-light"
        subprocess.run(
            ["gsettings", "set", "org.gnome.desktop.interface", "color-scheme", scheme],
            stderr=subprocess.DEVNULL,
            stdout=subprocess.DEVNULL,
        )


def _parse_ini(text: str) -> dict[str, list[str]]:
    sections: dict[str, list[str]] = {"": []}
    current = ""
    for line in text.splitlines():
        if line.startswith("[") and "]" in line:
            current = line.strip()
            sections.setdefault(current, [])
        else:
            sections[current].append(line)
    return sections


def _dump_ini(sections: dict[str, list[str]]) -> str:
    out: list[str] = []
    for name, lines in sections.items():
        if name:
            out.append(name)
        out.extend(lines)
    return "\n".join(out).rstrip("\n") + "\n"


@log_exception
def apply_qt(colours: dict[str, str], mode: str) -> None:
    scheme_text = render_file("kde.colors", colours, mode)

    # Standalone scheme file (shows up in KDE's colour scheme chooser)
    _write_if_changed(data_dir / "color-schemes" / "Caelestia.colors", scheme_text)

    # KDE apps read the active colours from kdeglobals, so merge the scheme's groups into it
    # (what plasma-apply-colorscheme does), keeping the user's other settings.
    path = config_dir / "kdeglobals"
    existing = _parse_ini(path.read_text() if path.exists() else "")
    new = _parse_ini(scheme_text)
    for name in list(existing):
        if name.startswith("[Colors:") or name.startswith("[ColorEffects:") or name in ("[WM]", "[KDE]"):
            del existing[name]
    general = existing.setdefault("[General]", [])
    general[:] = [ln for ln in general if not ln.startswith(("ColorScheme=", "Name="))]
    general.insert(0, "ColorScheme=Caelestia")
    for name, lines in new.items():
        if name and name != "[General]":
            existing[name] = lines
    changed = _write_if_changed(path, _dump_ini(existing))

    # Tell running KDE/Qt apps to reload their palette (KGlobalSettings.PaletteChanged)
    if changed and shutil.which("dbus-send"):
        subprocess.run(
            [
                "dbus-send",
                "--session",
                "/KGlobalSettings",
                "org.kde.KGlobalSettings.notifyChange",
                "int32:0",
                "int32:0",
            ],
            stderr=subprocess.DEVNULL,
            stdout=subprocess.DEVNULL,
        )


@log_exception
def apply_zed(colours: dict[str, str], mode: str) -> None:
    _write_if_changed(config_dir / "zed" / "themes" / "caelestia.json", render_file("zed.json", colours, mode))


TARGETS = {
    "alacritty": apply_alacritty,
    "niri": apply_niri,
    "gtk": apply_gtk,
    "qt": apply_qt,
    "zed": apply_zed,
}


def apply_colours(colours: dict[str, str], mode: str) -> None:
    for name, fn in TARGETS.items():
        if _enabled(name):
            fn(colours, mode)


def setup(colours: dict[str, str], mode: str) -> None:
    """Wire the user-owned configs to the generated files (idempotent). Renders everything first."""
    apply_colours(colours, mode)

    # Alacritty: import the generated colours
    alacritty = config_dir / "alacritty" / "alacritty.toml"
    imp = str(theme_dir / "alacritty.toml")
    if not alacritty.exists():
        atomic_write(alacritty, f'[general]\nimport = ["{imp}"]\n')
        log(f"created {alacritty}")
    elif imp not in alacritty.read_text():
        warn(f'add this to {alacritty}:\n[general]\nimport = ["{imp}"]')

    # niri: include the generated colours last so they override the layout section
    niri = config_dir / "niri" / "config.kdl"
    inc = f'include "{theme_dir / "niri.kdl"}"'
    if niri.exists() and inc not in niri.read_text():
        backup = niri.with_name(niri.name + ".bak-pre-theming")
        if not backup.exists():
            shutil.copy2(niri, backup)
        original = niri.read_text()
        atomic_write(niri, original.rstrip("\n") + f"\n\n// Wallpaper colours from caelestia (keep last)\n{inc}\n")
        valid = subprocess.run(["niri", "validate", "-c", str(niri)], capture_output=True, text=True)
        if valid.returncode != 0:
            atomic_write(niri, original)
            error(f"niri rejected the include, restored config.kdl:\n{valid.stderr or valid.stdout}")
        else:
            log(f"added include to {niri} (backup: {backup.name})")

    # Zed: select the generated theme if there are no settings yet
    zed = config_dir / "zed" / "settings.json"
    if not zed.exists():
        atomic_write(zed, '{\n  "theme": "Caelestia"\n}\n')
        log(f"created {zed}")
    elif '"Caelestia"' not in zed.read_text():
        warn(f'set "theme": "Caelestia" in {zed} to use the generated Zed theme')
