import QtQuick
import ".."

Item {
    id: root
    signal clicked()
    implicitWidth: label.implicitWidth
    implicitHeight: label.implicitHeight

    property string stamp: Qt.formatDateTime(new Date(), "HH:mm")

    Timer {
        interval: 1000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            const fresh = Qt.formatDateTime(new Date(), "HH:mm");
            if (fresh !== root.stamp) {
                root.stamp = fresh;
                dip.restart();
            }
        }
    }

    Text {
        id: label
        text: root.stamp
        color: Chroma.text
        font.family: Metrics.fontFamily
        font.pixelSize: 13
        font.bold: true
        opacity: 1
        SequentialAnimation {
            id: dip
            NumberAnimation { target: label; property: "opacity"; to: 0.35; duration: 160; easing.type: Easing.OutQuad }
            NumberAnimation { target: label; property: "opacity"; to: 1; duration: 220; easing.type: Easing.InQuad }
        }
    }

    MouseArea {
        anchors.fill: parent
        anchors.margins: -6
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
        scale: containsMouse ? 1.05 : 1
        Behavior on scale { SpringAnimation { spring: 3; damping: 0.3 } }
    }
}
