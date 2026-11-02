import QtQuick
import Quickshell

// Replacement for HyprlandFocusGrab (niri has no focus-grab protocol).
// While `active`, emits `cleared` once any of `windows` has had keyboard focus and then lost it,
// e.g. because the user clicked another client. Windows must use a layer-shell keyboardFocus
// mode that lets focus leave (OnDemand).
Item {
    id: root

    property bool active
    property list<QtObject> windows

    signal cleared

    visible: false

    QtObject {
        id: state

        property bool hadFocus
    }

    onActiveChanged: state.hadFocus = false

    Repeater {
        model: root.windows

        Connections {
            required property QtObject modelData

            function onActiveChanged(): void {
                if (!root.active)
                    return;
                if (modelData.active)
                    state.hadFocus = true;
                else if (state.hadFocus) {
                    state.hadFocus = false;
                    root.cleared();
                }
            }

            target: modelData
        }
    }
}
