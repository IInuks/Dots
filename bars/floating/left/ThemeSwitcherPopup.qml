import QtQuick
import QtQuick.Layouts
import ".."

// Round placeholder button's click target: pick between the static "Mono"
// (Mr.-Robot) palette and an "Adaptive" one pulled from the current
// wallpaper via matugen (Theme.qml). Falls back to disabled+hint text if
// matugen isn't available yet or hasn't produced a palette.
PopupBase {
    id: popup
    popupWidth: 170
    popupHeight: col.implicitHeight + 20

    // Retry in case the initial check (Theme.qml, Component.onCompleted)
    // ran before the wallpaper path or matugen availability was ready --
    // otherwise a one-time startup race could leave Adaptive permanently
    // stuck disabled until the whole bar restarts.
    Component.onCompleted: if (Theme.adaptivePalette === null) Theme.refreshAdaptive()

    ColumnLayout {
        id: col
        width: popup.popupWidth - 20
        spacing: 2

        Rectangle {
            id: monoRow
            Layout.fillWidth: true
            radius: 6
            implicitHeight: 28
            color: Settings.themeMode === "mono" ? Qt.alpha(Theme.textMuted, 0.16) : (monoArea.containsMouse ? Qt.alpha(Theme.textMuted, 0.10) : "transparent")

            Text {
                anchors.left: parent.left
                anchors.leftMargin: 8
                anchors.verticalCenter: parent.verticalCenter
                text: "Mono"
                color: Theme.text
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSizeSmall
            }
            MouseArea {
                id: monoArea
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: Settings.setThemeMode("mono")
            }
        }

        Rectangle {
            id: adaptiveRow
            Layout.fillWidth: true
            radius: 6
            implicitHeight: 28
            enabled: Theme.adaptivePalette !== null
            opacity: enabled ? 1 : 0.4
            color: Settings.themeMode === "adaptive" ? Qt.alpha(Theme.textMuted, 0.16) : (adaptiveArea.containsMouse ? Qt.alpha(Theme.textMuted, 0.10) : "transparent")

            Text {
                anchors.left: parent.left
                anchors.leftMargin: 8
                anchors.verticalCenter: parent.verticalCenter
                text: "Adaptiv"
                color: Theme.text
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSizeSmall
            }
            MouseArea {
                id: adaptiveArea
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: Settings.setThemeMode("adaptive")
            }
        }

        Text {
            Layout.fillWidth: true
            Layout.topMargin: 2
            visible: Theme.adaptivePalette === null
            text: Theme.matugenAvailable ? "Erzeuge Palette…" : "matugen nicht gefunden"
            color: Theme.textMuted
            font.family: Theme.fontFamily
            font.pixelSize: 9
            font.italic: true
            wrapMode: Text.WordWrap
        }
    }
}
