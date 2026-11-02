pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Effects
import Quickshell
import Caelestia
import Caelestia.Components
import Caelestia.Config
import qs.components
import qs.services

ClipRect {
    id: root

    required property ShellScreen screen
    required property bool fullscreen

    readonly property string output: screen.name
    readonly property int activeWsId: Niri.activeWorkspaceFor(output)?.idx ?? 1
    readonly property int activeWsIdx: workspaceIndex(activeWsId)
    readonly property int shown: Math.max(1, Config.bar.workspaces.shown)

    readonly property var wsIds: {
        if (Config.bar.workspaces.showUnoccupied)
            return Array.from({
                length: shown
            }, (_, i) => i + 1);

        const workspaces = Niri.workspacesFor(root.output).filter(w => w.idx === activeWsId || Niri.windowsForWs(w.id).length > 0);
        const currentIdx = workspaces.findIndex(w => w.idx === activeWsId);
        if (currentIdx < 0)
            return [];

        const end = CUtils.clamp(currentIdx + 1, Math.min(shown, workspaces.length), workspaces.length);
        const start = Math.max(0, end - shown);

        return workspaces.slice(start, end).map(w => w.idx);
    }

    readonly property var workspaces: {
        CUtils.dependency(workspaces.itemsDirty);
        return wsIds.map(id => workspaces.itemAtIndex(workspaceIndex(id)));
    }

    // Only relevant for when showUnoccupied is true
    readonly property int groupOffset: {
        if (!Config.bar.workspaces.showUnoccupied)
            return 0;
        return Math.floor((activeWsId - 1) / shown) * shown;
    }

    property real blur: 0

    function workspaceIndex(id: int): int {
        if (!Config.bar.workspaces.showUnoccupied)
            return wsIds.indexOf(id);

        let index = id - 1;
        while (index < 0)
            index += shown;
        return index % shown;
    }

    implicitWidth: Tokens.sizes.bar.innerWidth
    implicitHeight: workspaces.layoutHeight + workspaces.anchors.margins * 2

    color: Colours.tPalette.m3surfaceContainer
    radius: Tokens.rounding.full

    Item {
        anchors.fill: parent
        visible: !root.fullscreen

        layer.enabled: root.blur > 0
        layer.effect: MultiEffect {
            blurEnabled: true
            blur: root.blur
            blurMax: 32
        }

        Loader {
            asynchronous: true
            opacity: Config.bar.workspaces.occupiedBg ? 1 : 0
            active: opacity > 0

            anchors.fill: parent
            anchors.margins: Tokens.padding.extraSmall

            sourceComponent: OccupiedBg {
                workspaces: root.workspaces
                wsSpacing: workspaces.spacing
            }

            Behavior on opacity {
                Anim {
                    type: Anim.DefaultEffects
                }
            }
        }

        LazyListView {
            id: workspaces

            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: Tokens.padding.extraSmall
            implicitHeight: contentHeight

            spacing: Tokens.spacing.extraSmall
            removeDuration: Tokens.anim.durations.expressiveDefaultEffects

            model: ScriptModel {
                values: root.wsIds
            }

            delegate: Workspace {
                activeWsId: root.activeWsId
                ws: Config.bar.workspaces.showUnoccupied ? root.groupOffset + index + 1 : modelData
                output: root.output

                displayType: Config.bar.workspaces.displayType
                showWindows: Config.bar.workspaces.showWindows
                iconRules: GlobalConfig.bar.workspaces.workspaceIcons
                activeLabel: Config.bar.workspaces.activeLabel
                occupiedLabel: Config.bar.workspaces.occupiedLabel
                label: Config.bar.workspaces.label
            }
        }

        Loader {
            asynchronous: true
            opacity: Config.bar.workspaces.showUnoccupied ? 0 : 1
            active: opacity > 0

            anchors.fill: parent
            anchors.margins: Tokens.padding.extraSmall

            sourceComponent: GapMarkers {
                workspaces: root.workspaces
                wsSpacing: workspaces.spacing
            }

            Behavior on opacity {
                Anim {
                    type: Anim.DefaultEffects
                }
            }
        }

        Loader {
            asynchronous: true
            anchors.left: workspaces.left
            anchors.right: workspaces.right
            active: Config.bar.workspaces.activeIndicator

            sourceComponent: ActiveIndicator {
                activeWs: {
                    CUtils.dependency(workspaces.itemsDirty);
                    return workspaces.itemAtIndex(root.activeWsIdx) as Workspace;
                }
                mask: workspaces
            }
        }

        MouseArea {
            anchors.fill: workspaces
            onClicked: event => {
                const ws = (workspaces.itemAt(event.x, event.y) as Workspace)?.ws;
                if (!ws)
                    return;
                if (root.activeWsId !== ws || !Niri.isFocusedScreen(root.screen))
                    Niri.focusWorkspace(ws, root.output);
            }
        }

        Behavior on scale {
            Anim {}
        }

        Behavior on opacity {
            Anim {
                type: Anim.DefaultEffects
            }
        }
    }

    Behavior on blur {
        Anim {
            type: Anim.StandardSmall
        }
    }

    Behavior on implicitHeight {
        Anim {}
    }
}
