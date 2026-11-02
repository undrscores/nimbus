import QtQuick
import Caelestia.Config
import qs.components
import qs.services
import qs.modules.nexus

Item {
    id: root

    implicitWidth: icon.implicitHeight + Tokens.padding.small
    implicitHeight: icon.implicitHeight

    StateLayer {
        // Cursed workaround to make the height larger than the parent
        anchors.fill: undefined
        anchors.centerIn: parent
        implicitWidth: implicitHeight
        implicitHeight: icon.implicitHeight + Tokens.padding.small
        radius: Tokens.rounding.full
        onClicked: WindowFactory.toggle()
    }

    MaterialIcon {
        id: icon

        anchors.centerIn: parent

        text: "settings"
        color: Colours.palette.m3onSurfaceVariant
        fontStyle: Tokens.font.icon.builders.small.weight(Font.Bold).build()
    }
}
