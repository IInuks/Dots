import QtQuick
import QtQuick.Layouts
import ".."

// One Power-popup row. Restart/shutdown require `needsConfirm`, per spec 4
// "Power-Menü": first click arms a "Wirklich?" state for 3s, a second click
// within that window actually runs the action -- avoids a separate modal
// dialog for just two of the five actions.
Rectangle {
    id: root

    property string label: ""
    property string iconName: ""
    property color tint: Theme.text
    property bool needsConfirm: false
    signal activated()

    property bool _armed: false

    Layout.fillWidth: true
    radius: 6
    color: area.containsMouse ? Qt.alpha(Theme.textMuted, 0.15) : "transparent"
    implicitHeight: 30

    Timer {
        id: disarmTimer
        interval: 3000
        onTriggered: root._armed = false
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 8
        anchors.rightMargin: 8
        spacing: 8

        Icon { name: root.iconName; size: 13; tint: root._armed ? Theme.urgent : root.tint }
        Text {
            text: root._armed ? "Wirklich?" : root.label
            color: root._armed ? Theme.urgent : Theme.text
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSizeSmall
            Layout.fillWidth: true
        }
    }

    MouseArea {
        id: area
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            if (!root.needsConfirm || root._armed) {
                disarmTimer.stop();
                root._armed = false;
                root.activated();
            } else {
                root._armed = true;
                disarmTimer.restart();
            }
        }
    }
}
