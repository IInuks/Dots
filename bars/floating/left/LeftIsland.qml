import QtQuick
import ".."

IslandBase {
    id: island
    side: "left"
    popups: ({ "monitor": monitorPopupComponent, "theme": themeSwitcherPopupComponent })

    Item {
        id: tempBtn
        implicitWidth: tempRow.implicitWidth
        implicitHeight: tempRow.implicitHeight
        anchors.verticalCenter: parent.verticalCenter

        Row {
            id: tempRow
            spacing: 4
            anchors.verticalCenter: parent.verticalCenter

            Icon { name: "temp"; size: 13; tint: Theme.textMuted; anchors.verticalCenter: parent.verticalCenter }
            Text {
                text: Math.round(SysMonData.cpuTemp) + "°C"
                color: Theme.text
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSizeNormal
                anchors.verticalCenter: parent.verticalCenter
            }
        }

        MouseArea {
            anchors.fill: parent
            anchors.margins: -4
            cursorShape: Qt.PointingHandCursor
            onClicked: PopupState.toggle("monitor")
        }
    }

    Workspaces {
        outputName: island.outputName
        anchors.verticalCenter: parent.verticalCenter
    }

    Tray {
        hostWindow: island
        anchors.verticalCenter: parent.verticalCenter
    }

    // Theme switcher: was an undecided placeholder, now opens Mono/Adaptive
    // palette choice (Theme.qml, ThemeSwitcherPopup.qml).
    Rectangle {
        id: themeBtn
        width: 18
        height: 18
        radius: 9
        color: "transparent"
        border.width: Theme.islandBorderWidth
        border.color: Theme.islandBorderColor
        anchors.verticalCenter: parent.verticalCenter

        MouseArea {
            anchors.fill: parent
            anchors.margins: -4
            cursorShape: Qt.PointingHandCursor
            onClicked: PopupState.toggle("theme")
        }
    }

    Component {
        id: monitorPopupComponent
        SystemMonitorPopup {}
    }
    Component {
        id: themeSwitcherPopupComponent
        ThemeSwitcherPopup {}
    }
}
