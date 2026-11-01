import QtQuick

// Klick = stumm, Mausrad = lauter/leiser.
Item {
    id: root
    property color accent: "#2f6fd0"

    anchors.verticalCenter: parent ? parent.verticalCenter : undefined
    width: row.implicitWidth
    height: row.implicitHeight
    opacity: Audio.available ? 1 : 0.5

    Row {
    id: row
    spacing: 7

    Text {
        anchors.verticalCenter: parent.verticalCenter
        width: 16
        text: Audio.muted || Audio.volume === 0 ? Theme.iVolOff : Audio.volume < 0.4 ? Theme.iVolLow : Theme.iVolHigh
        font.family: Theme.icons
        font.pixelSize: 14
        color: Audio.muted ? Theme.inkSoft : root.accent
    }
    Text {
        anchors.verticalCenter: parent.verticalCenter
        text: Audio.available ? (Audio.muted ? "stumm" : Math.round(Audio.volume * 100) + "%") : "–"
        font.family: Theme.font
        font.pixelSize: Theme.textSize
        font.weight: Font.Bold
        font.strikeout: Audio.muted
        color: Audio.muted ? Theme.inkSoft : Theme.ink
    }

    }

    MouseArea {
        anchors.fill: parent
        anchors.margins: -6
        cursorShape: Qt.PointingHandCursor
        onClicked: Audio.toggleMute()
        onWheel: wheel => Audio.step(wheel.angleDelta.y > 0 ? 1 : -1)
    }
}
