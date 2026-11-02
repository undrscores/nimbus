import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import Caelestia.I18n
import qs.components
import qs.services

ColumnLayout {
    id: root

    required property var client // niri window

    anchors.fill: parent
    spacing: Tokens.spacing.small

    Label {
        Layout.topMargin: Tokens.padding.extraLargeIncreased

        text: root.client?.title ?? Tr.tr("No active client")
        wrapMode: Text.WrapAtWordBoundaryOrAnywhere

        font: Tokens.font.body.builders.large.weight(Font.Medium).build()
    }

    Label {
        text: root.client?.app_id ?? Tr.tr("No active client")
        color: Colours.palette.m3tertiary

        font: Tokens.font.body.large
    }

    StyledRect {
        Layout.fillWidth: true
        Layout.preferredHeight: 1
        Layout.leftMargin: Tokens.padding.extraLargeIncreased
        Layout.rightMargin: Tokens.padding.extraLargeIncreased
        Layout.topMargin: Tokens.spacing.medium
        Layout.bottomMargin: Tokens.spacing.largeIncreased

        color: Colours.palette.m3secondary
    }

    Detail {
        icon: "location_on"
        text: Tr.trCtx("Window id: %1", "window id").arg(root.client?.id ?? "unknown")
        color: Colours.palette.m3primary
    }

    Detail {
        icon: "location_searching"
        // TRANSLATORS: %1 = column index, %2 = tile index in the column
        text: Tr.tr("Position: %1, %2").arg(root.client?.layout?.pos_in_scrolling_layout?.[0] ?? -1).arg(root.client?.layout?.pos_in_scrolling_layout?.[1] ?? -1)
    }

    Detail {
        icon: "resize"
        // TRANSLATORS: %1/%2 = width and height in pixels; the x is a multiplication sign
        text: Tr.tr("Size: %1 x %2").arg(root.client?.layout?.window_size?.[0] ?? -1).arg(root.client?.layout?.window_size?.[1] ?? -1)
        color: Colours.palette.m3tertiary
    }

    Detail {
        icon: "workspaces"
        // TRANSLATORS: %1 = workspace name, %2 = workspace index
        text: {
            const ws = Niri.workspaces.find(w => w.id === root.client?.workspace_id);
            return Tr.tr("Workspace: %1 (%2)").arg(ws?.name ?? ws?.idx ?? -1).arg(ws?.idx ?? -1);
        }
        color: Colours.palette.m3secondary
    }

    Detail {
        icon: "desktop_windows"
        text: {
            const ws = Niri.workspaces.find(w => w.id === root.client?.workspace_id);
            if (ws)
                return Tr.tr("Monitor: %1").arg(ws.output);
            return Tr.tr("Monitor: unknown");
        }
    }

    Detail {
        icon: "account_tree"
        // TRANSLATORS: %1 = process id
        text: Tr.tr("Process id: %1").arg(String(root.client?.pid ?? -1))
        color: Colours.palette.m3primary
    }

    Detail {
        icon: "picture_in_picture_center"
        text: root.client?.is_floating ? Tr.tr("Floating: yes") : Tr.tr("Floating: no")
        color: Colours.palette.m3secondary
    }

    Item {
        Layout.fillHeight: true
    }

    component Detail: RowLayout {
        id: detail

        required property string icon
        required property string text
        property alias color: icon.color

        Layout.leftMargin: Tokens.padding.large
        Layout.rightMargin: Tokens.padding.large
        Layout.fillWidth: true

        spacing: Tokens.spacing.medium

        MaterialIcon {
            id: icon

            Layout.alignment: Qt.AlignVCenter
            text: detail.icon
        }

        StyledText {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter

            text: detail.text
            elide: Text.ElideRight
            font: Tokens.font.body.medium
        }
    }

    component Label: StyledText {
        Layout.leftMargin: Tokens.padding.large
        Layout.rightMargin: Tokens.padding.large
        Layout.fillWidth: true
        elide: Text.ElideRight
        horizontalAlignment: Text.AlignHCenter
        animate: true
    }
}
