import QtQuick
import Quickshell
import ".."
import "../Bar"

// No inline "are you sure?" row -- instead each action needs to be held
// down until its ring finishes filling (same radial-gauge visual as the
// CPU/volume meters in the dock), so a stray click can never trigger a
// shutdown.
PopupFrame {
    id: root
    property real screenWidthHint: 1920
    screenWidth: root.screenWidthHint
    panelWidth: Metrics.powerWidth
    panelHeight: Metrics.powerHeight

    readonly property var actions: [
        { key: "lock", label: "Sperren", glyph: "lock", cmd: "swaylock" },
        { key: "logout", label: "Abmelden", glyph: "logout", cmd: "mmsg dispatch quit" },
        { key: "restart", label: "Neustart", glyph: "refresh", cmd: "systemctl reboot" },
        { key: "poweroff", label: "Ausschalten", glyph: "power", cmd: "systemctl poweroff" }
    ]

    Row {
        anchors.centerIn: parent
        spacing: 18

        Repeater {
            model: root.actions

            delegate: Column {
                id: cell
                required property var modelData
                spacing: 6

                property real holdProgress: 0

                NumberAnimation {
                    id: fillAnim
                    target: cell
                    property: "holdProgress"
                    from: cell.holdProgress
                    to: 1
                    duration: 900
                    easing.type: Easing.Linear
                    onStopped: {
                        if (cell.holdProgress >= 0.999) {
                            Quickshell.execDetached(["sh", "-c", cell.modelData.cmd]);
                            Popups.close();
                        }
                    }
                }
                NumberAnimation {
                    id: releaseAnim
                    target: cell
                    property: "holdProgress"
                    to: 0
                    duration: 180
                    easing.type: Easing.OutQuad
                }

                Meter {
                    anchors.horizontalCenter: parent.horizontalCenter
                    implicitWidth: 46
                    implicitHeight: 46
                    glyphName: cell.modelData.glyph
                    ringColor: cell.modelData.key === "poweroff" ? Chroma.bad : Chroma.accent
                    value: cell.holdProgress

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onPressed: {
                            releaseAnim.stop();
                            fillAnim.from = cell.holdProgress;
                            fillAnim.restart();
                        }
                        onReleased: {
                            fillAnim.stop();
                            releaseAnim.restart();
                        }
                        onCanceled: {
                            fillAnim.stop();
                            releaseAnim.restart();
                        }
                    }
                }

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: cell.modelData.label
                    color: Chroma.textFaint
                    font.family: Metrics.fontFamily
                    font.pixelSize: 10
                }
            }
        }
    }
}
