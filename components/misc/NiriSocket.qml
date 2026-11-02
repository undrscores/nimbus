import QtQuick
import Quickshell
import Quickshell.Io

// Line-based JSON client for the niri IPC socket ($NIRI_SOCKET).
Scope {
    id: root

    property bool autoReconnect: true
    readonly property bool connected: socket.connected

    signal message(var data)
    // Emitted shortly after the socket connects; safe to write requests.
    signal ready

    function send(request: var): void {
        if (!socket.connected)
            return;
        socket.write(JSON.stringify(request) + "\n");
        socket.flush();
    }

    // The initial `connected` value comes from a binding, so no change signal fires for it.
    Component.onCompleted: {
        if (socket.connected)
            readyTimer.start();
    }

    Socket {
        id: socket

        path: Quickshell.env("NIRI_SOCKET")
        connected: path !== ""

        parser: SplitParser {
            onRead: line => {
                let data;
                try {
                    data = JSON.parse(line);
                } catch (e) {
                    console.warn("NiriSocket: bad json:", line);
                    return;
                }
                root.message(data);
            }
        }

        onConnectedChanged: {
            if (connected)
                readyTimer.restart();
            else if (root.autoReconnect && path !== "")
                reconnectTimer.restart();
        }
    }

    Timer {
        id: readyTimer

        interval: 150
        onTriggered: root.ready()
    }

    Timer {
        id: reconnectTimer

        interval: 1500
        onTriggered: socket.connected = true
    }
}
