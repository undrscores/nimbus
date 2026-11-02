pragma Singleton

import QtQuick
import Quickshell
import Caelestia.Config

// Auto-hide mode (burn-in protection for OLED panels). While enabled, everything permanently on screen (bar,
// border frame, desktop clock and visualiser) is hidden; the bar and panels still appear on hover, drag or keybind.
// Toggle at runtime with `qs -c caelestia ipc call shortcut trigger autoHide`; GlobalConfig.general.autoHide sets
// the default at startup.
Singleton {
    id: root

    property bool enabled: GlobalConfig.general.autoHide

    function toggle(): void {
        enabled = !enabled;
    }
}
