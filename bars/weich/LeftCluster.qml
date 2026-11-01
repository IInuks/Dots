import QtQuick
import Quickshell
import Quickshell.Wayland

// Left side: workspace pills + focused window title, each its own soft
// segment inside one transparent, screen-edge-anchored window.
PanelWindow {
    id: win

    property var modelData
    screen: modelData

    anchors { top: true; left: true }
    margins.top: Theme.marginTop - Theme.topReserve
    margins.left: Theme.marginSide
    color: "transparent"
    exclusiveZone: 0
    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.namespace: "weich-left"
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

    implicitWidth: row.implicitWidth
    implicitHeight: Theme.paneHeight

    readonly property string screenName: modelData ? modelData.name : ""
    readonly property var tags: Mango.tagsFor(screenName)
    readonly property int activeIndex: Mango.activeTagIndex(screenName)

    Row {
        id: row
        spacing: Theme.groupSpacing

        Pane {
            Row {
                spacing: 6
                Repeater {
                    model: win.tags
                    delegate: Rectangle {
                        id: dot
                        required property var modelData
                        readonly property bool active: modelData.index === win.activeIndex
                        readonly property bool occupied: modelData.client_count > 0

                        width: 20
                        height: 20
                        radius: 10
                        anchors.verticalCenter: parent.verticalCenter
                        color: active ? Theme.activeFill : "transparent"
                        border.width: active ? 0 : 1
                        border.color: modelData.is_urgent ? Theme.accent : Qt.alpha(Theme.foreground, occupied ? 0.5 : 0.22)
                        Behavior on color { ColorAnimation { duration: Theme.animFast } }

                        Text {
                            anchors.centerIn: parent
                            text: modelData.index
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSizeSmall
                            color: active ? Theme.background : (dot.occupied ? Theme.foreground : Theme.muted)
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: Mango.selectTag(win.screenName, modelData.index)
                        }
                    }
                }
            }
        }

        Pane {
            visible: titleText.text.length > 0
            Text {
                id: titleText
                text: Mango.focusedTitle(win.screenName)
                elide: Text.ElideRight
                maximumLineCount: 1
                width: Math.min(implicitWidth, 260)
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSizeSmall
                color: Theme.muted
            }
        }
    }
}
