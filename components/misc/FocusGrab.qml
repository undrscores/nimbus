import QtQuick
import Quickshell

// Replacement for HyprlandFocusGrab (niri has no focus-grab protocol).
// While `active`, emits `cleared` once any of `windows` has had keyboard focus and then lost it,
// e.g. because the user clicked another client. Windows must use a layer-shell keyboardFocus
// mode that lets focus leave (OnDemand).
Scope {
    id: root

    property bool active
    property list<QtObject> windows

    signal cleared

    property bool hadFocus

    onActiveChanged: hadFocus = false

    Instantiator {
        model: root.windows

        delegate: Connections {
            id: conn

            required property QtObject modelData

            function onActiveChanged(): void {
                if (!root.active)
                    return;
                if (target.active)
                    root.hadFocus = true;
                else if (root.hadFocus) {
                    root.hadFocus = false;
                    root.cleared();
                }
            }

            target: modelData?.backingWindow ?? null
        }
    }
}
