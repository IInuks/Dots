import QtQuick
import Quickshell
import "../../"
import "../../components"
import "../../services"

// Full-screen session menu: deep gradient with stars, one big ringed
// planet (or a black hole, Config planetStyle) as focal point, ring-shaped
// buttons below.
//
// Safety: an action only fires after a *hold* -- press and keep holding
// (or press Enter) and the ring fills over ~0.9 s. Let go early to cancel.
Item {
    id: root
    property string screenName: ""
    readonly property bool shown: Popups.isOpen("session", screenName)

    property real _p: shown ? 1 : 0
    Behavior on _p { NumberAnimation { duration: Theme.tSlow * 1.5; easing.type: Theme.easeOut } }
    visible: _p > 0.001
    opacity: _p

    property int sel: 1
    property int arming: -1       // index being held
    property real charge: 0
    readonly property bool hole: Theme.c.planetStyle === "blackhole"

    focus: shown
    Component.onCompleted: Shots.register("session@" + screenName, root)
    onShownChanged: {
        if (shown) {
            forceActiveFocus();
            sel = 1;
        }
        arming = -1;
        charge = 0;
    }

    Keys.onLeftPressed: { cancel(); sel = (sel + Session.actions.length - 1) % Session.actions.length; }
    Keys.onRightPressed: { cancel(); sel = (sel + 1) % Session.actions.length; }
    Keys.onReturnPressed: arm(sel)
    Keys.onEnterPressed: arm(sel)
    Keys.onEscapePressed: Popups.close()

    function arm(i) {
        sel = i;
        arming = i;
        chargeAnim.restart();
    }
    function cancel() {
        if (arming < 0)
            return;
        chargeAnim.stop();
        arming = -1;
        drain.restart();
    }

    NumberAnimation {
        id: chargeAnim
        target: root
        property: "charge"
        to: 1
        duration: 900 * (1 - root.charge)
        onFinished: if (root.arming >= 0) Session.run(Session.actions[root.arming].id)
    }
    NumberAnimation {
        id: drain
        target: root
        property: "charge"
        to: 0
        duration: 250
    }

    // ---- sky
    Rectangle {
        anchors.fill: parent
        gradient: Gradient {
            GradientStop { position: 0; color: Theme.alpha(Theme.bgTop, 0.96) }
            GradientStop { position: 0.55; color: Theme.alpha(Theme.bgMid, 0.96) }
            GradientStop { position: 1; color: Theme.alpha(Theme.bgBottom, 0.96) }
        }
    }
    StarField {
        anchors.fill: parent
        count: 110
        seed: 42
        maxSize: 3
        active: root.visible
    }
    MouseArea {
        anchors.fill: parent
        onClicked: Popups.close()
    }

    // ---- the planet
    Item {
        id: planetBox
        anchors.horizontalCenter: parent.horizontalCenter
        y: parent.height * 0.22 + (1 - root._p) * 40
        width: 230
        height: 230

        Orb {
            id: planet
            anchors.fill: parent
            color: Session.actions[root.sel].color
            ring: true
            glowing: true
            glowStrength: 0.9 + root.charge * 0.8
            glowSize: 2.2
            crescent: 0.2
            scale: 1 + root.charge * 0.06
            visible: opacity > 0.01
            opacity: root.hole ? 0 : 1
            Behavior on opacity { NumberAnimation { duration: Theme.tMed } }
        }
        // planet as a black hole (Config planetStyle), disk tinted by the action
        BlackHole {
            anchors.centerIn: parent
            width: parent.width * 1.6
            height: width
            palette: "tint"
            tint: Session.actions[root.sel].color
            glowStrength: 0.8 + root.charge * 0.8
            scale: 1 + root.charge * 0.06
            visible: opacity > 0.01
            opacity: root.hole ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: Theme.tMed } }
        }
        // a moon on a slow orbit
        Item {
            anchors.centerIn: parent
            width: 380
            height: 380
            Orb {
                width: 26; height: 26
                x: parent.width - width
                y: parent.height / 2 - 13
                color: "#DCE3F5"
                crescent: 0.3
            }
            RotationAnimation on rotation {
                running: root.visible && Theme.animations
                from: 0; to: 360
                duration: 40000
                loops: Animation.Infinite
            }
        }
    }

    Column {
        anchors.horizontalCenter: parent.horizontalCenter
        y: planetBox.y + planetBox.height + 70
        spacing: Theme.s2
        KLabel {
            anchors.horizontalCenter: parent.horizontalCenter
            text: Session.actions[root.sel].label
            font.pixelSize: Theme.fHuge * 0.7
            font.weight: Font.Bold
        }
        KLabel {
            anchors.horizontalCenter: parent.horizontalCenter
            role: "muted"
            text: root.arming >= 0 ? "Festhalten …" : "Gedrückt halten zum Bestätigen  ·  ←→ wählen  ·  esc zurück"
        }
    }

    // ---- ring buttons
    Row {
        anchors.horizontalCenter: parent.horizontalCenter
        y: planetBox.y + planetBox.height + 170
        spacing: Theme.s6

        Repeater {
            model: Session.actions
            Item {
                id: btn
                required property var modelData
                required property int index
                readonly property bool isSel: root.sel === index
                width: 92
                height: 92
                scale: isSel ? 1.08 : 1
                Behavior on scale { NumberAnimation { duration: Theme.tPop; easing.type: Theme.easePop; easing.overshoot: 1.8 } }

                Ring {
                    anchors.fill: parent
                    thickness: 6
                    color: btn.modelData.color
                    trackColor: Theme.alpha(btn.modelData.color, btn.isSel ? 0.25 : 0.12)
                    animated: false
                    value: root.arming === btn.index ? root.charge : 0
                    glowing: btn.isSel
                }
                IconBadge {
                    anchors.centerIn: parent
                    width: 64; height: 64
                    glyph: btn.modelData.glyph
                    color: btn.modelData.color
                    active: btn.isSel
                    interactive: false
                }
                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onEntered: if (root.arming < 0) root.sel = btn.index
                    onPressed: root.arm(btn.index)
                    onReleased: if (root.charge < 1) root.cancel()
                    onCanceled: root.cancel()
                }
            }
        }
    }
}
