import QtQuick
import "../../"

// Bar prompt section 4, "clock" row: HH in primary, ":" + mm in tertiary,
// all 13px DemiBold, spacing 0, no seconds. Click opens the calendar
// dropdown (menus prompt 1.4, Stage 3) -- the click catcher is a sibling of
// the Row, not a child of it: a Row child can't use `anchors.fill` (Row
// positions children itself and warns/no-ops on that), so the click area
// lives one level up.
Item {
    id: root

    property date _now: new Date()

    implicitWidth: content.implicitWidth
    implicitHeight: content.implicitHeight

    Timer {
        interval: 1000
        running: true
        repeat: true
        // Re-derive each tick instead of a naive ++seconds counter so a
        // system clock jump (suspend/resume, manual date change) is
        // reflected immediately rather than drifting.
        onTriggered: root._now = new Date()
        triggeredOnStart: true
    }

    Row {
        id: content
        anchors.verticalCenter: parent.verticalCenter
        spacing: 0

        Text {
            text: Qt.formatDateTime(root._now, "HH")
            font.family: Style.textFont
            font.pixelSize: Style.fontBodyLarge
            font.weight: Font.DemiBold
            color: Colors.primary
        }
        Text {
            text: Qt.formatDateTime(root._now, ":mm")
            font.family: Style.textFont
            font.pixelSize: Style.fontBodyLarge
            font.weight: Font.DemiBold
            color: Colors.tertiary
        }
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: DropdownState.toggle("calendar")
    }
}
