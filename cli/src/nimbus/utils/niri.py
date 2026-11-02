"""Minimal niri IPC helpers (via `niri msg --json`)."""

import json
import subprocess
from typing import Any


def _msg(*args: str) -> Any:
    out = subprocess.check_output(["niri", "msg", "--json", *args], text=True)
    return json.loads(out)


def monitors() -> list[dict[str, Any]]:
    """Outputs in a Hyprland-like shape: name, x, y, width, height (physical px), refreshRate, focused."""
    outputs = _msg("outputs")
    try:
        focused = _msg("focused-output").get("name")
    except (subprocess.CalledProcessError, AttributeError, json.JSONDecodeError):
        focused = None

    result = []
    for name, o in outputs.items():
        mode_idx = o.get("current_mode")
        mode = o["modes"][mode_idx] if mode_idx is not None else None
        logical = o.get("logical") or {}
        if mode is None:
            continue
        result.append(
            {
                "name": name,
                "x": logical.get("x", 0),
                "y": logical.get("y", 0),
                "width": mode["width"],
                "height": mode["height"],
                "refreshRate": mode["refresh_rate"] / 1000,
                "focused": name == focused,
            }
        )

    if result and not any(m["focused"] for m in result):
        result[0]["focused"] = True
    return result
