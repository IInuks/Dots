import QtQuick
import "../../"

// Bar prompt section 4, "notifications" row: count, icon U+F009A. Stage 5
// (the bar's own popup daemon, bar prompt "Vorgehen" ordering, see
// README.md) isn't built yet, so NotificationState.count is usually 0 in
// practice -- but it now reads the real (empty-until-Stage-5) shared store
// instead of a local stub, and clicking opens the Stage 3 notification
// center dropdown. Always visible (unlike wifi/bluetooth/brightness/
// battery, the spec doesn't list notifications among the "hidden without
// data" widgets). The click catcher is a sibling of the Row, not a child of
// it: a Row child can't use `anchors.fill` (Row positions children itself
// and warns/no-ops on that), so the click area lives one level up.
Item {
    id: root

    implicitWidth: content.implicitWidth
    implicitHeight: content.implicitHeight

    Row {
        id: content
        anchors.verticalCenter: parent.verticalCenter
        spacing: 4

        Text {
            font.family: Style.iconFont
            font.pixelSize: 14
            color: Colors.primary
            text: "\u{F009A}"
        }
        Text {
            font.family: Style.textFont
            font.pixelSize: 12
            font.weight: Font.Medium
            color: Colors.tertiary
            text: String(NotificationState.count)
        }
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: DropdownState.toggle("notifications")
    }
}
