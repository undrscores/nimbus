import Quickshell
import Quickshell.Io

// Line-based JSON client for the niri IPC socket ($NIRI_SOCKET).
Socket {
    id: root

    property bool autoReconnect: true

    signal message(var data)

    function send(request: var): void {
        if (!connected)
            return;
        write(JSON.stringify(request) + "\n");
        flush();
    }

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
        if (!connected && autoReconnect && path !== "")
            reconnect.restart();
    }

    property Timer reconnectTimer: Timer {
        id: reconnect

        interval: 1000
        onTriggered: root.connected = true
    }
}
