import QtQuick

// HH:mm with a colon that pulses gently every second -- the one always-on
// bar animation that never needs a hover to be noticed.
Item {
    id: root
    signal clicked()
    implicitWidth: row.implicitWidth
    implicitHeight: 20

    property string hh: "00"
    property string mm: "00"

    Timer {
        interval: 1000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            const t = Qt.formatDateTime(new Date(), "HH:mm").split(":");
            root.hh = t[0];
            root.mm = t[1];
            colon.pulse();
        }
    }

    Row {
        id: row
        spacing: 2
        anchors.centerIn: parent

        Text { text: root.hh; color: Theme.text; font.pixelSize: 13; font.bold: true }
        Text {
            id: colon
            text: ":"
            color: Theme.accent
            font.pixelSize: 13
            font.bold: true
            opacity: 1
            function pulse() { pulseAnim.restart(); }
            SequentialAnimation {
                id: pulseAnim
                NumberAnimation { target: colon; property: "opacity"; to: 0.25; duration: 220; easing.type: Easing.OutQuad }
                NumberAnimation { target: colon; property: "opacity"; to: 1; duration: 220; easing.type: Easing.InQuad }
            }
        }
        Text { text: root.mm; color: Theme.text; font.pixelSize: 13; font.bold: true }
    }

    MouseArea {
        anchors.fill: parent
        anchors.margins: -6
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
        scale: containsMouse ? 1.06 : 1
        Behavior on scale { SpringAnimation { spring: 3; damping: 0.3 } }
    }
}
