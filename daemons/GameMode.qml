import QtQuick
import Quickshell
import Quickshell.Io
import Caelestia
import Caelestia.Config
import Caelestia.I18n
import Caelestia.State
import qs.services

Scope {
    id: root

    // niri has no runtime option setting, so game mode only affects the shell itself
    // (RuntimeState.gameMode is read by the drawers, desktop clock blur, etc.).
    function syncState(enableDisable: bool): void {
        if (!enableDisable || !GlobalConfig.utilities.toasts.gameModeChanged)
            return;
        if (RuntimeState.gameMode)
            Toaster.toast(Tr.tr("Game mode enabled"), Tr.tr("Disabled shell blur and rounding"), "gamepad");
        else
            Toaster.toast(Tr.tr("Game mode disabled"), Tr.tr("Shell settings restored"), "gamepad");
    }

    Component.onCompleted: syncState(false)

    Connections {
        function onGameModeChanged(): void {
            root.syncState(true);
        }

        target: RuntimeState
    }

    IpcHandler {
        function isEnabled(): bool {
            return RuntimeState.gameMode;
        }

        function toggle(): void {
            RuntimeState.gameMode = !RuntimeState.gameMode;
        }

        function enable(): void {
            RuntimeState.gameMode = true;
        }

        function disable(): void {
            RuntimeState.gameMode = false;
        }

        target: "gameMode"
    }
}
