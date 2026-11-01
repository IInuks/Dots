import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland

// Die Leiste: eine schwebende Kapsel (oder bündig am Rand, siehe Werkbank).
//   links : Nest-Knopf (Launcher) · Tag-Eier · Fenstertitel
//   mitte : Uhr (-> Kalender) · das Überraschungsei
//   rechts: System-Ringe · Lautstärke · Werkbank · Power
PanelWindow {
    id: bar
    required property var modelData
    screen: modelData
    readonly property string screenName: modelData.name

    anchors { top: true; left: true; right: true }
    margins { top: Theme.gap; left: Theme.gap; right: Theme.gap }
    implicitHeight: Theme.barHeight
    exclusiveZone: Theme.barHeight + (Settings.data.floating ? Theme.gap : 0)
    color: "transparent"
    WlrLayershell.namespace: "eierschale-bar"
    WlrLayershell.layer: WlrLayer.Top

    // x-Mitte eines Leisten-Elements in Bildschirmkoordinaten
    function centerOf(item) { return item.mapToItem(null, item.width / 2, 0).x + Theme.gap; }
    function pop(id, item) { Ui.toggle(id, bar.screenName, centerOf(item)); }

    Rectangle {
        id: body
        anchors.fill: parent
        radius: Settings.data.floating ? Theme.radius : 0
        color: Theme.alpha(Theme.base, Settings.data.opacity)
        border.width: Settings.data.floating ? 1 : 0
        border.color: Theme.line
        Behavior on radius { NumberAnimation { duration: Theme.tMed } }

        // ein Hauch Akzent von unten, damit die Kapsel "leuchtet"
        Rectangle {
            anchors.fill: parent
            radius: parent.radius
            gradient: Gradient {
                GradientStop { position: 0.0; color: "transparent" }
                GradientStop { position: 1.0; color: Theme.alpha(Theme.accent, 0.07) }
            }
        }

        // Einblenden beim Start: die Kapsel "schlüpft" von oben herein
        transform: Translate { id: slide; y: -60 }
        opacity: 0
        Component.onCompleted: { intro.start(); Shots.register("bar@" + bar.screenName, body); }
        ParallelAnimation {
            id: intro
            NumberAnimation { target: slide; property: "y"; to: 0; duration: Theme.ms(700); easing.type: Easing.OutBack; easing.overshoot: 1.4 }
            NumberAnimation { target: body; property: "opacity"; to: 1; duration: Theme.ms(400) }
        }

        // ------------------------------------------------------ links
        RowLayout {
            id: left
            anchors.left: parent.left
            anchors.leftMargin: 6
            anchors.verticalCenter: parent.verticalCenter
            spacing: 6

            Knopf {
                id: nest
                Layout.preferredWidth: 34; Layout.preferredHeight: 32
                active: Ui.openId === "launcher" && Ui.screenName === bar.screenName
                onClicked: bar.pop("launcher", nest)
                // drei Eier im Nest
                Item {
                    anchors.centerIn: parent
                    width: 24; height: 18
                    Repeater {
                        model: 3
                        EggShape {
                            required property int index
                            width: 9; height: 12
                            x: index * 7.5
                            y: index === 1 ? 0 : 3
                            fill: index === 1 ? Theme.accent : (index === 0 ? Theme.accent2 : Theme.text)
                            shine: false
                            rotation: (index - 1) * 14
                        }
                    }
                    Rectangle { width: 26; height: 5; radius: 2.5; x: -1; y: 13; color: Theme.textDim }
                }
            }

            TagEggs { screenName: bar.screenName }

            Label {
                id: title
                Layout.maximumWidth: Math.max(60, bar.width / 2 - center.width / 2 - 330)
                Layout.leftMargin: 6
                text: Mango.title
                color: Theme.textDim
                size: 12.5
                visible: text.length > 0
                // neuer Titel gleitet kurz von links rein
                transform: Translate { id: titleShift }
                onTextChanged: if (Theme.motion) titleIn.restart()
                ParallelAnimation {
                    id: titleIn
                    NumberAnimation { target: titleShift; property: "x"; from: -10; to: 0; duration: Theme.tMed; easing.type: Easing.OutCubic }
                    NumberAnimation { target: title; property: "opacity"; from: 0.2; to: 1; duration: Theme.tMed }
                }
            }
        }

        // ------------------------------------------------------ mitte
        Row {
            id: center
            anchors.centerIn: parent
            spacing: 4

            Knopf {
                id: clockBtn
                width: clock.implicitWidth + 24; height: 32
                anchors.verticalCenter: parent.verticalCenter
                active: Ui.openId === "calendar" && Ui.screenName === bar.screenName
                onClicked: bar.pop("calendar", clockBtn)
                BarClock { id: clock; anchors.centerIn: parent }
            }
            SurpriseEgg {
                id: surprise
                anchors.verticalCenter: parent.verticalCenter
                active: Ui.openId === "egg" && Ui.screenName === bar.screenName
                onClicked: {
                    if (Eggs.ringing) { Eggs.ringing = false; return; }
                    bar.pop("egg", surprise);
                }
            }
        }

        // ------------------------------------------------------ rechts
        RowLayout {
            anchors.right: parent.right
            anchors.rightMargin: 6
            anchors.verticalCenter: parent.verticalCenter
            spacing: 4

            Knopf {
                id: statsBtn
                Layout.preferredHeight: 32
                Layout.preferredWidth: statsRow.implicitWidth + 20
                active: Ui.openId === "system" && Ui.screenName === bar.screenName
                onClicked: bar.pop("system", statsBtn)
                Row {
                    id: statsRow
                    anchors.centerIn: parent
                    spacing: 10
                    MiniRing { value: Stats.cpu; icon: "cpu"; tint: Theme.accent }
                    MiniRing { value: Stats.mem; icon: "memory"; tint: Theme.accent2 }
                }
            }

            Knopf {
                id: volBtn
                Layout.preferredHeight: 32
                Layout.preferredWidth: volRow.implicitWidth + 20
                active: Ui.openId === "control" && Ui.screenName === bar.screenName
                onClicked: m => {
                    if (m.button === Qt.MiddleButton) Audio.toggleMute();
                    else bar.pop("control", volBtn);
                }
                onWheel: w => Audio.nudge(w.angleDelta.y > 0 ? 0.03 : -0.03)
                Row {
                    id: volRow
                    anchors.centerIn: parent
                    spacing: 6
                    Icon { name: Audio.icon(); size: 17; color: Audio.muted ? Theme.textFaint : Theme.text }
                    Label {
                        text: Math.round(Audio.volume * 100)
                        size: 12
                        color: Theme.textDim
                        font.family: Theme.mono
                        visible: Audio.ready
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }
            }

            Knopf {
                id: studioBtn
                Layout.preferredWidth: 32; Layout.preferredHeight: 32
                active: Ui.openId === "studio" && Ui.screenName === bar.screenName
                onClicked: bar.pop("studio", studioBtn)
                Icon {
                    anchors.centerIn: parent; name: "tune"; size: 17
                    rotation: studioBtn.hovered ? 90 : 0
                    Behavior on rotation { NumberAnimation { duration: Theme.tSlow; easing.type: Easing.OutBack } }
                }
            }

            Knopf {
                id: powerBtn
                Layout.preferredWidth: 32; Layout.preferredHeight: 32
                tint: Theme.bad
                onClicked: Ui.open("session", bar.screenName, -1)
                Icon { anchors.centerIn: parent; name: "power"; size: 17; color: powerBtn.hovered ? Theme.bad : Theme.text }
            }
        }
    }
}
