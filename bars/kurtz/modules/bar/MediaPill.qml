import QtQuick
import "../../"
import "../../components"
import "../../services"

// Now playing: round cover with a spinning dotted orbit while playing,
// semibold title, muted artist. Middle click = play/pause, scroll = skip.
Pill {
    id: root
    padding: Theme.s2
    spacing: Theme.s2
    acceptedButtons: Qt.LeftButton | Qt.MiddleButton

    signal open

    onClicked: m => m.button === Qt.MiddleButton ? Player.toggle() : root.open()
    onWheel: e => e.angleDelta.y > 0 ? Player.prev() : Player.next()

    Item {
        anchors.verticalCenter: parent.verticalCenter
        width: Theme.pillHeight - 4
        height: width
        CoverArt {
            anchors.centerIn: parent
            width: parent.width - 8
            height: width
            source: Player.art
            orbit: true
            spinning: Player.playing
            orbitGap: 3
        }
    }
    Column {
        anchors.verticalCenter: parent.verticalCenter
        spacing: -1
        KLabel {
            width: Math.min(170, implicitWidth)
            text: Player.title
            font.weight: Font.DemiBold
            font.pixelSize: Theme.fSmall + 1
        }
        KLabel {
            width: Math.min(170, implicitWidth)
            role: "muted"
            text: Player.artist
            font.pixelSize: Theme.fTiny + 1
        }
    }
    KIcon {
        anchors.verticalCenter: parent.verticalCenter
        text: Player.playing ? Glyphs.pause : Glyphs.play
        size: 14
        color: Theme.media
    }
}
