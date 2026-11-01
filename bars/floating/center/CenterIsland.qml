import QtQuick
import ".."

IslandBase {
    id: island
    side: "center"
    popups: ({
        "calendar": calendarPopupComponent,
        "notifications": notificationsPopupComponent
    })

    property date _now: new Date()
    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: island._now = new Date()
    }
    function _pad(n) { return n < 10 ? "0" + n : "" + n; }

    Text {
        text: island._pad(island._now.getHours()) + ":" + island._pad(island._now.getMinutes())
        color: Theme.text
        font.family: Theme.fontFamily
        font.pixelSize: Theme.fontSizeNormal
        anchors.verticalCenter: parent.verticalCenter

        MouseArea {
            anchors.fill: parent
            anchors.margins: -4
            cursorShape: Qt.PointingHandCursor
            onClicked: PopupState.toggle("calendar")
        }
    }

    Item {
        width: bellIcon.width
        height: bellIcon.height
        anchors.verticalCenter: parent.verticalCenter

        Icon {
            id: bellIcon
            name: "bell"
            size: 14
            tint: Theme.text
        }

        Rectangle {
            visible: NotificationState.unreadCount > 0
            width: 8
            height: 8
            radius: 4
            color: Theme.urgent
            anchors.top: parent.top
            anchors.right: parent.right
            anchors.topMargin: -2
            anchors.rightMargin: -2
        }

        MouseArea {
            anchors.fill: parent
            anchors.margins: -4
            cursorShape: Qt.PointingHandCursor
            onClicked: PopupState.toggle("notifications")
        }
    }

    Component {
        id: calendarPopupComponent
        CalendarWeatherPopup {}
    }
    Component {
        id: notificationsPopupComponent
        NotificationsPopup {}
    }
}
