pragma Singleton

import Quickshell
import Quickshell.Io

// Niri has no global-shortcuts protocol, so shortcuts are triggered over Quickshell IPC instead:
//   qs -c caelestia ipc call shortcut trigger <name>
// which is bound from niri's config.kdl. See docs/niri.md.
Singleton {
    id: root

    property var registered: ({})

    function register(shortcut: QtObject): void {
        registered[shortcut.name] = shortcut;
    }

    function unregister(shortcut: QtObject): void {
        if (registered[shortcut.name] === shortcut)
            delete registered[shortcut.name];
    }

    function trigger(name: string): bool {
        const s = registered[name];
        if (!s)
            return false;
        s.pressed();
        s.released();
        return true;
    }

    IpcHandler {
        function trigger(name: string): bool {
            return root.trigger(name);
        }

        function press(name: string): bool {
            const s = root.registered[name];
            if (!s)
                return false;
            s.pressed();
            return true;
        }

        function release(name: string): bool {
            const s = root.registered[name];
            if (!s)
                return false;
            s.released();
            return true;
        }

        function list(): string {
            return Object.keys(root.registered).sort().map(n => `${n}\t${root.registered[n].description}`).join("\n");
        }

        target: "shortcut"
    }
}
