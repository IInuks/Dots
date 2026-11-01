import QtQuick

// Ein klickbares Symbol als Inhalt eines ausgepackten Geschenks.
Item {
    id: root
    property alias text: glyph.text
    property color tint: Theme.ink
    signal clicked

    anchors.verticalCenter: parent ? parent.verticalCenter : undefined
    implicitWidth: 24
    implicitHeight: 24
    width: implicitWidth
    height: implicitHeight

    IconLabel {
        id: glyph
        anchors.centerIn: parent
        tint: root.tint
        scale: area.pressed ? 0.85 : area.containsMouse ? 1.15 : 1
        Behavior on scale { NumberAnimation { duration: 160; easing.type: Easing.OutBack } }
    }
    MouseArea {
        id: area
        anchors.fill: parent
        anchors.margins: -6
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}
