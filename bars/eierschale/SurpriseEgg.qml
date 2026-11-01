import QtQuick

// Das Überraschungsei in der Leistenmitte. Wackelt alle 45 s kurz (wenn
// erlaubt), zeigt einen Ring, solange die Sanduhr läuft, und bimmelt
// (zittert + färbt sich), wenn sie abgelaufen ist.
Item {
    id: root
    property bool active: false
    signal clicked()
    width: 32; height: 32

    Rectangle {
        anchors.fill: parent
        radius: 16
        color: root.active ? Theme.alpha(Theme.accent, 0.22) : (ma.containsMouse ? Theme.alpha(Theme.text, 0.08) : "transparent")
        Behavior on color { ColorAnimation { duration: Theme.tFast } }
    }

    Ring {
        anchors.fill: parent
        anchors.margins: 1
        visible: Eggs.timerRunning
        value: Eggs.timerProgress
        thickness: 2.5
        track: "transparent"
        tint: Theme.accent2
    }

    EggShape {
        id: egg
        anchors.centerIn: parent
        width: 17; height: 22
        fill: Eggs.ringing ? Theme.accent2 : Theme.text
        band: Theme.accent
        transformOrigin: Item.Bottom
        scale: ma.pressed ? 0.85 : (ma.containsMouse ? 1.12 : 1)
        Behavior on scale { NumberAnimation { duration: Theme.tFast; easing.type: Easing.OutBack } }
    }

    SequentialAnimation {
        id: wobble
        loops: Eggs.ringing ? Animation.Infinite : 1
        NumberAnimation { target: egg; property: "rotation"; to: -14; duration: Theme.ms(90); easing.type: Easing.OutQuad }
        NumberAnimation { target: egg; property: "rotation"; to: 12; duration: Theme.ms(120); easing.type: Easing.InOutQuad }
        NumberAnimation { target: egg; property: "rotation"; to: -8; duration: Theme.ms(110); easing.type: Easing.InOutQuad }
        NumberAnimation { target: egg; property: "rotation"; to: 5; duration: Theme.ms(100); easing.type: Easing.InOutQuad }
        NumberAnimation { target: egg; property: "rotation"; to: 0; duration: Theme.ms(120); easing.type: Easing.OutQuad }
        PauseAnimation { duration: Eggs.ringing ? 400 : 0 }
    }
    Connections {
        target: Eggs
        function onRingingChanged() { if (Eggs.ringing) wobble.restart(); else { wobble.stop(); egg.rotation = 0; } }
    }
    Timer {
        interval: 45000
        repeat: true
        running: Settings.data.eggWobble && Theme.motion && !root.active
        onTriggered: wobble.restart()
    }

    MouseArea {
        id: ma
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onEntered: if (Theme.motion && !wobble.running) wobble.restart()
        onClicked: root.clicked()
    }
}
