import QtQuick
import "../../"

// Gear icon opening SettingsDropdown.qml (currently just the workspace-
// indicator style picker, see Config.workspaceStyle). Always visible --
// same "always available" treatment as ClockWidget.qml, not gated by an
// `available` property like the hardware-dependent widgets. Item root
// (not Row) for the same reason as WifiWidget.qml: the click catcher is a
// sibling of the Row, not a child of it -- a Row child can't use
// `anchors.fill` (Row positions children itself and warns/no-ops on that).
Item {
    id: root

    implicitWidth: content.implicitWidth
    implicitHeight: content.implicitHeight

    Row {
        id: content
        anchors.verticalCenter: parent.verticalCenter

        Text {
            font.family: Style.iconFont
            font.pixelSize: 14
            color: DropdownState.open === "settings" ? Colors.primary : Colors.tertiary
            text: "\u{F0493}"
            Behavior on color { ColorAnimation { duration: Style.anim150 } }
        }
    }

    MouseArea {
        anchors.fill: parent
        anchors.margins: -4
        cursorShape: Qt.PointingHandCursor
        onClicked: DropdownState.toggle("settings")
    }
}
