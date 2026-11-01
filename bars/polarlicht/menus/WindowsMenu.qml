pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import Quickshell.Wayland
import qs
import qs.widgets

// Fensterliste über wlr-foreign-toplevel: Klick = fokussieren, Mittelklick = schließen
MenuCard {
    id: root
    name: "windows"
    width: 420
    height: Math.min(col.implicitHeight + 40, 620)

    readonly property var wins: ToplevelManager.toplevels.values.filter(t => !/quickshell/i.test(t.appId))

    Column {
        id: col
        anchors.left: parent.left; anchors.right: parent.right
        anchors.top: parent.top; anchors.margins: 20
        spacing: 12

        Item {
            width: parent.width; height: 30
            Txt { anchors.verticalCenter: parent.verticalCenter; text: "Fenster"; font.pixelSize: 18; font.weight: Font.Bold }
            Txt {
                anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter
                text: root.wins.length + " offen · Mittelklick schließt"
                font.pixelSize: 11; color: Theme.textDim
            }
        }

        Txt { visible: root.wins.length === 0; text: "Keine Fenster offen"; color: Theme.textDim }

        ListView {
            width: parent.width
            height: Math.min(contentHeight, 520)
            spacing: 6
            clip: true
            model: root.wins
            boundsBehavior: Flickable.StopAtBounds

            add: Transition { NumberAnimation { properties: "opacity"; from: 0; to: 1; duration: Theme.dur(250) } }
            remove: Transition {
                ParallelAnimation {
                    NumberAnimation { property: "opacity"; to: 0; duration: Theme.dur(220) }
                    NumberAnimation { property: "x"; to: 60; duration: Theme.dur(220); easing.type: Easing.InCubic }
                }
            }
            displaced: Transition { NumberAnimation { properties: "y"; duration: Theme.dur(260); easing.type: Easing.OutCubic } }

            delegate: Rectangle {
                id: w
                required property Toplevel modelData
                required property int index
                readonly property var entry: DesktopEntries.heuristicLookup(modelData.appId)
                width: ListView.view.width
                height: 58; radius: 16
                color: modelData.activated ? Theme.accentSoft : hov.hovered ? Theme.surfaceHi : Theme.surface
                border.width: modelData.activated ? 1 : 0
                border.color: Theme.accent
                Behavior on color { ColorAnimation { duration: Theme.dur(160) } }
                HoverHandler { id: hov }

                Image {
                    id: ic
                    x: 12; anchors.verticalCenter: parent.verticalCenter
                    width: 32; height: 32
                    sourceSize: Qt.size(64, 64)
                    asynchronous: true
                    source: Quickshell.iconPath(w.entry?.icon ?? w.modelData.appId, true)
                    visible: status === Image.Ready
                }
                Glyph { anchors.centerIn: ic; visible: !ic.visible; text: Icons.window; size: 22; color: Theme.accent }

                Column {
                    anchors.left: ic.right; anchors.leftMargin: 12
                    anchors.right: closeBtn.left; anchors.rightMargin: 8
                    anchors.verticalCenter: parent.verticalCenter
                    Txt { width: parent.width; text: w.entry?.name ?? w.modelData.appId; font.weight: Font.DemiBold }
                    Txt { width: parent.width; text: w.modelData.title; font.pixelSize: 11; color: Theme.textDim }
                }

                MouseArea {
                    id: wMa
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    acceptedButtons: Qt.LeftButton | Qt.MiddleButton
                    onClicked: m => {
                        if (m.button === Qt.MiddleButton) w.modelData.close()
                        else { w.modelData.activate(); Hub.close() }
                    }
                }
                RoundButton {
                    id: closeBtn
                    anchors.right: parent.right; anchors.rightMargin: 12
                    anchors.verticalCenter: parent.verticalCenter
                    size: 30; icon: Icons.close
                    opacity: hov.hovered ? 1 : 0
                    Behavior on opacity { NumberAnimation { duration: Theme.dur(150) } }
                    onClicked: w.modelData.close()
                }
            }
        }
    }
}
