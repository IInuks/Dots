import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland

// Brief top-right toast for new notifications (spec 4
// "Benachrichtigungsmenü": "Neue Benachrichtigungen erscheinen zusätzlich
// kurz als Toast... im gleichen Stil"), same island look as the bar itself.
// NotificationState.push() already skips setting `toast` while DND is on.
PanelWindow {
    id: toastWin

    readonly property var toast: NotificationState.toast

    anchors.top: true
    anchors.right: true
    // See IslandBase.qml: TopGapReserve.qml's exclusiveZone pushes this
    // surface down too, so compensate the same way.
    margins.top: Theme.marginTop - Theme.topReserveZone
    margins.right: Theme.marginSide

    color: "transparent"
    exclusiveZone: 0
    visible: toastWin.toast !== null
    implicitWidth: 260
    implicitHeight: visible ? box.implicitHeight : 1

    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.namespace: "floating-toast"
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

    Timer {
        id: hideTimer
        interval: 4500
        onTriggered: NotificationState.toast = null
    }
    onToastChanged: if (toastWin.toast) hideTimer.restart()

    Rectangle {
        id: box
        width: parent.width
        implicitHeight: col.implicitHeight + 20
        color: Theme.islandBackgroundColor
        radius: Theme.islandRadius
        border.width: Theme.islandBorderWidth
        border.color: Theme.islandBorderColor

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: NotificationState.toast = null
        }

        ColumnLayout {
            id: col
            anchors.fill: parent
            anchors.margins: 10
            spacing: 2

            Text {
                text: toastWin.toast ? (toastWin.toast.appName || "") : ""
                color: Theme.textMuted
                font.family: Theme.fontFamily
                font.pixelSize: 10
            }
            Text {
                Layout.fillWidth: true
                visible: !!(toastWin.toast && toastWin.toast.summary)
                text: toastWin.toast ? (toastWin.toast.summary || "") : ""
                color: Theme.text
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSizeSmall
                font.bold: true
                wrapMode: Text.WordWrap
            }
            Text {
                Layout.fillWidth: true
                visible: !!(toastWin.toast && toastWin.toast.body)
                text: toastWin.toast ? (toastWin.toast.body || "") : ""
                color: Theme.textMuted
                font.family: Theme.fontFamily
                font.pixelSize: 10
                wrapMode: Text.WordWrap
                maximumLineCount: 3
                elide: Text.ElideRight
            }
        }
    }
}
