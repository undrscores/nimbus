pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Caelestia.I18n
import qs.components.misc

// Compositor state and control for niri, over its IPC socket.
// Workspaces/windows are plain JS objects as sent by niri (see niri-ipc docs).
Singleton {
    id: root

    // State
    property var workspaces: []     // sorted by output, then idx
    property var windows: []
    property int focusedWindowId: -1
    property string focusedOutputName: ""
    property bool overviewOpen: false

    readonly property var focusedWorkspace: workspaces.find(w => w.is_focused) ?? null
    readonly property var activeToplevel: windows.find(w => w.id === focusedWindowId) ?? null
    readonly property int activeWsIdx: focusedWorkspace?.idx ?? 1
    readonly property string focusedMonitor: focusedWorkspace?.output ?? focusedOutputName

    // Keyboard
    property var kbLayoutNames: []
    property int kbLayoutIdx: 0
    property bool capsLock
    property bool numLock

    readonly property string defaultKbLayout: kbMap.get(kbLayoutNames[0]) ?? "??"
    readonly property string kbLayoutFull: kbLayoutNames[kbLayoutIdx] ?? Tr.trCtx("Unknown", "keyboard layout")
    readonly property string kbLayout: kbMap.get(kbLayoutFull) ?? "??"
    readonly property var kbMap: new Map()

    signal configReloaded

    // --- Queries ---

    function monitorNames(): list<string> {
        return Quickshell.screens.map(s => s.name);
    }

    function workspacesFor(output: string): var {
        return workspaces.filter(w => w.output === output);
    }

    function activeWorkspaceFor(output: string): var {
        return workspaces.find(w => w.output === output && w.is_active) ?? null;
    }

    // niri workspaces are addressed per output by idx (1-based).
    function workspaceAt(output: string, idx: int): var {
        return workspaces.find(w => w.output === output && w.idx === idx) ?? null;
    }

    function windowsForWsIdx(output: string, idx: int): var {
        const ws = workspaceAt(output, idx);
        return ws ? windowsForWs(ws.id) : [];
    }

    function windowsForWs(wsId: int): var {
        return windows.filter(w => w.workspace_id === wsId);
    }

    function windowsForOutput(output: string): var {
        const ids = new Set(workspacesFor(output).map(w => w.id));
        return windows.filter(w => ids.has(w.workspace_id));
    }

    // niri's window IPC may not expose fullscreen on all versions; treated as false when absent.
    function hasFullscreen(output: string): bool {
        const ws = activeWorkspaceFor(output);
        return ws ? windows.some(w => w.workspace_id === ws.id && w.is_fullscreen === true) : false;
    }

    function isFocusedScreen(screen: ShellScreen): bool {
        return screen?.name === focusedMonitor;
    }

    // --- Commands ---

    function action(name: string, args: var): void {
        const a = {};
        a[name] = args ?? {};
        actions.send({
            Action: a
        });
    }

    // Focus a workspace by its per-output index (1-based). Defaults to the focused output.
    function focusWorkspace(idx: int, output: string): void {
        if (output && output !== focusedMonitor)
            action("FocusMonitor", {
                output
            });
        action("FocusWorkspace", {
            reference: {
                Index: idx
            }
        });
    }

    function focusWorkspaceRelative(delta: int): void {
        action(delta > 0 ? "FocusWorkspaceDown" : "FocusWorkspaceUp");
    }

    function focusWindow(id: int): void {
        action("FocusWindow", {
            id
        });
    }

    function closeWindow(id: int): void {
        action("CloseWindow", {
            id
        });
    }

    function toggleFloating(id: int): void {
        action("ToggleWindowFloating", {
            id
        });
    }

    function moveWindowToWorkspace(id: int, idx: int): void {
        action("MoveWindowToWorkspace", {
            window_id: id,
            reference: {
                Index: idx
            },
            focus: true
        });
    }

    function switchKbLayout(idx: int): void {
        action("SwitchLayout", {
            layout: {
                Index: idx
            }
        });
    }

    function powerMonitors(on: bool): void {
        action(on ? "PowerOnMonitors" : "PowerOffMonitors");
    }

    // --- Event handling ---

    function updateWindow(win: var): void {
        const next = windows.filter(w => w.id !== win.id);
        next.push(win);
        windows = next;
        if (win.is_focused)
            focusedWindowId = win.id;
    }

    function handleEvent(ev: var): void {
        const name = Object.keys(ev)[0];
        const d = ev[name];

        switch (name) {
        case "WorkspacesChanged":
            workspaces = sortWorkspaces(d.workspaces);
            break;
        case "WorkspaceActivated": {
            const target = workspaces.find(w => w.id === d.id);
            if (!target)
                break;
            workspaces = workspaces.map(w => {
                const nw = Object.assign({}, w);
                if (w.output === target.output)
                    nw.is_active = w.id === d.id;
                if (d.focused)
                    nw.is_focused = w.id === d.id;
                return nw;
            });
            if (d.focused)
                focusedOutputName = target.output;
            break;
        }
        case "WorkspaceActiveWindowChanged":
            workspaces = workspaces.map(w => w.id === d.workspace_id ? Object.assign({}, w, {
                active_window_id: d.active_window_id
            }) : w);
            break;
        case "WorkspaceUrgencyChanged":
            workspaces = workspaces.map(w => w.id === d.id ? Object.assign({}, w, {
                is_urgent: d.urgent
            }) : w);
            break;
        case "WindowsChanged":
            windows = d.windows;
            focusedWindowId = d.windows.find(w => w.is_focused)?.id ?? -1;
            break;
        case "WindowOpenedOrChanged":
            updateWindow(d.window);
            break;
        case "WindowClosed":
            windows = windows.filter(w => w.id !== d.id);
            if (focusedWindowId === d.id)
                focusedWindowId = -1;
            break;
        case "WindowFocusChanged":
            focusedWindowId = d.id ?? -1;
            break;
        case "WindowUrgencyChanged":
            windows = windows.map(w => w.id === d.id ? Object.assign({}, w, {
                is_urgent: d.urgent
            }) : w);
            break;
        case "KeyboardLayoutsChanged":
            kbLayoutNames = d.keyboard_layouts.names;
            kbLayoutIdx = d.keyboard_layouts.current_idx;
            break;
        case "KeyboardLayoutSwitched":
            kbLayoutIdx = d.idx;
            break;
        case "OverviewOpenedOrClosed":
            overviewOpen = d.is_open;
            break;
        case "ConfigLoaded":
            configReloaded();
            break;
        }
    }

    function sortWorkspaces(list: var): var {
        return list.slice().sort((a, b) => a.output === b.output ? a.idx - b.idx : a.output.localeCompare(b.output));
    }

    NiriSocket {
        id: events

        onConnectedChanged: if (connected)
            send("EventStream")
        onMessage: data => {
            // First reply is {"Ok":{"Handled":null}}; events follow.
            if (data.Ok !== undefined || data.Err !== undefined) {
                if (data.Err !== undefined)
                    console.warn("niri EventStream error:", data.Err);
                return;
            }
            root.handleEvent(data);
        }
    }

    NiriSocket {
        id: actions

        onMessage: data => {
            if (data.Err !== undefined)
                console.warn("niri action error:", data.Err);
        }
    }

    // Caps/num lock aren't exposed over niri IPC; poll the keyboard LEDs.
    Process {
        running: true
        command: ["sh", "-c", "while :; do c=0; n=0; for f in /sys/class/leds/*::capslock/brightness; do [ -r \"$f\" ] && [ \"$(cat \"$f\")\" -gt 0 ] && c=1; done; for f in /sys/class/leds/*::numlock/brightness; do [ -r \"$f\" ] && [ \"$(cat \"$f\")\" -gt 0 ] && n=1; done; echo \"$c $n\"; sleep 0.25; done"]
        stdout: SplitParser {
            onRead: line => {
                const [c, n] = line.split(" ");
                root.capsLock = c === "1";
                root.numLock = n === "1";
            }
        }
    }

    FileView {
        id: kbLayoutFile

        path: Quickshell.env("CAELESTIA_XKB_RULES_PATH") || "/usr/share/X11/xkb/rules/base.lst"
        onLoaded: {
            const layoutMatch = text().match(/! layout\n([\s\S]*?)\n\n/);
            if (layoutMatch) {
                const lines = layoutMatch[1].split("\n");
                for (const line of lines) {
                    if (!line.trim() || line.trim().startsWith("!"))
                        continue;

                    const match = line.match(/^\s*([a-z]{2,})\s+([a-zA-Z() ]+)$/);
                    if (match)
                        root.kbMap.set(match[2], match[1]);
                }
            }

            const variantMatch = text().match(/! variant\n([\s\S]*?)\n\n/);
            if (variantMatch) {
                const lines = variantMatch[1].split("\n");
                for (const line of lines) {
                    if (!line.trim() || line.trim().startsWith("!"))
                        continue;

                    const match = line.match(/^\s*([a-zA-Z0-9_-]+)\s+([a-z]{2,}): (.+)$/);
                    if (match)
                        root.kbMap.set(match[3], match[2]);
                }
            }
            // kbMap isn't observable; poke dependents.
            root.kbLayoutNames = root.kbLayoutNames.slice();
        }
    }

    IpcHandler {
        function focusWorkspace(idx: int): void {
            root.focusWorkspace(idx);
        }

        function switchKbLayout(idx: int): void {
            root.switchKbLayout(idx);
        }

        target: "niri"
    }
}
