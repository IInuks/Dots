import QtQuick
import Quickshell

// Session: Vollbild. In der Mitte ein großes Ei, darunter die Aktionen.
// Zum Bestätigen GEDRÜCKT HALTEN -- der Ring füllt sich, das Ei bekommt
// Risse, und bei 100 % passiert es. Loslassen bricht ab.
Item {
    id: root
    property string screenName: ""
    readonly property bool shown: Ui.openId === "session" && Ui.screenName === screenName
    visible: opacity > 0.01
    opacity: shown ? 1 : 0
    Behavior on opacity { NumberAnimation { duration: Theme.tMed } }
    Component.onCompleted: Shots.register("session@" + screenName, root)

    property int sel: 2
    property real hold: 0
    property int holding: -1

    readonly property var actions: [
        { icon: "logout", label: "Abmelden", cmd: ["mmsg", "dispatch", "quit"] },
        { icon: "sleep", label: "Ruhezustand", cmd: ["loginctl", "suspend"] },
        { icon: "restart", label: "Neustart", cmd: ["loginctl", "reboot"] },
        { icon: "power", label: "Ausschalten", cmd: ["loginctl", "poweroff"] }
    ]

    onShownChanged: { holding = -1; hold = 0; }

    function start(i) { sel = i; holding = i; holdAnim.restart(); }
    function cancel() { holding = -1; holdAnim.stop(); backAnim.restart(); }
    function fire() {
        const a = actions[holding];
        holding = -1; hold = 0;
        Ui.close();
        Quickshell.execDetached(a.cmd);
    }

    NumberAnimation { id: holdAnim; target: root; property: "hold"; to: 1; duration: 900 * (1 - root.hold); onFinished: if (root.holding >= 0) root.fire() }
    NumberAnimation { id: backAnim; target: root; property: "hold"; to: 0; duration: 250; easing.type: Easing.OutCubic }

    Keys.onLeftPressed: sel = (sel + actions.length - 1) % actions.length
    Keys.onRightPressed: sel = (sel + 1) % actions.length
    Keys.onReturnPressed: ev => { if (!ev.isAutoRepeat) start(sel); }
    Keys.onReleased: ev => { if ((ev.key === Qt.Key_Return || ev.key === Qt.Key_Enter) && !ev.isAutoRepeat && holding >= 0) cancel(); }

    Rectangle {
        anchors.fill: parent
        color: Theme.alpha(Theme.base, 0.94)
        MouseArea { anchors.fill: parent; onClicked: Ui.close() }
    }

    // große Punkte im Hintergrund, ganz leicht
    Repeater {
        model: 18
        EggShape {
            required property int index
            readonly property real r: (index * 7919 % 97) / 97
            x: root.width * ((index * 37 % 100) / 100)
            y: root.height * ((index * 61 % 100) / 100)
            width: 20 + r * 50; height: width * 1.28
            rotation: (r - 0.5) * 60
            fill: Theme.alpha(index % 2 ? Theme.accent : Theme.accent2, 0.06)
            shine: false
        }
    }

    Column {
        anchors.centerIn: parent
        spacing: 40
        scale: root.shown ? 1 : 0.92
        Behavior on scale { NumberAnimation { duration: Theme.tSlow; easing.type: Easing.OutBack } }

        Item {
            anchors.horizontalCenter: parent.horizontalCenter
            width: 170; height: 220
            EggShape {
                id: bigEgg
                anchors.fill: parent
                fill: Theme.mix(Theme.text, Theme.bad, root.hold * 0.6)
                band: Theme.accent
                crack: root.hold
                rotation: root.holding >= 0 ? Math.sin(root.hold * 40) * root.hold * 6 : 0
            }
            Label {
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.top: parent.bottom; anchors.topMargin: 12
                text: root.holding >= 0 ? root.actions[root.holding].label + " …" : "Bis bald!"
                size: 20; bold: true
            }
        }

        Row {
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 22
            Repeater {
                model: root.actions
                Item {
                    id: act
                    required property var modelData
                    required property int index
                    readonly property bool on: root.sel === index
                    width: 110; height: 130
                    Item {
                        width: 96; height: 96
                        anchors.horizontalCenter: parent.horizontalCenter
                        scale: am.pressed ? 0.92 : (act.on ? 1.08 : 1)
                        Behavior on scale { NumberAnimation { duration: Theme.tFast; easing.type: Easing.OutBack } }
                        Rectangle {
                            anchors.fill: parent; radius: 48
                            color: act.on ? Theme.alpha(act.index === 3 ? Theme.bad : Theme.accent, 0.22) : Theme.surface2
                            Behavior on color { ColorAnimation { duration: Theme.tFast } }
                        }
                        Ring {
                            anchors.fill: parent
                            value: root.holding === act.index ? root.hold : 0
                            thickness: 5
                            track: "transparent"
                            tint: act.index === 3 ? Theme.bad : Theme.accent
                            animated: false
                        }
                        Icon { anchors.centerIn: parent; name: act.modelData.icon; size: 36; color: act.on ? (act.index === 3 ? Theme.bad : Theme.accent) : Theme.text }
                    }
                    Label { anchors.horizontalCenter: parent.horizontalCenter; y: 106; text: act.modelData.label; size: 13.5; bold: act.on }
                    MouseArea {
                        id: am
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onEntered: root.sel = act.index
                        onPressed: root.start(act.index)
                        onReleased: if (root.holding >= 0) root.cancel()
                        onCanceled: if (root.holding >= 0) root.cancel()
                    }
                }
            }
        }

        Label {
            anchors.horizontalCenter: parent.horizontalCenter
            text: "Gedrückt halten zum Bestätigen  ·  Esc schließt"
            size: 12.5; color: Theme.textFaint
        }
    }
}
