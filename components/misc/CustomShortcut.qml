import QtQuick

// Drop-in replacement for Hyprland's GlobalShortcut. Fired via ShortcutRegistry (Quickshell IPC).
QtObject {
    id: root

    property string name
    property string description

    signal pressed
    signal released

    Component.onCompleted: ShortcutRegistry.register(root)
    Component.onDestruction: ShortcutRegistry.unregister(root)
}
