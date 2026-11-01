import QtQuick
import Quickshell.Services.Pipewire
import ".."

IslandBase {
    id: island
    side: "right"
    popups: ({ "audio": audioPopupComponent, "power": powerPopupComponent })

    readonly property var sink: Pipewire.defaultAudioSink
    readonly property bool sinkReady: !!(sink && sink.ready && sink.audio)
    function isHeadphoneNode(node) {
        if (!node) return false;
        const p = node.properties || {};
        const form = p["device.form_factor"] || "";
        return form === "headphone" || form === "headset";
    }

    PwObjectTracker { objects: [Pipewire.defaultAudioSink] }

    Battery { anchors.verticalCenter: parent.verticalCenter }

    Item {
        id: volBtn
        implicitWidth: volRow.implicitWidth
        implicitHeight: volRow.implicitHeight
        anchors.verticalCenter: parent.verticalCenter

        Row {
            id: volRow
            spacing: 4
            anchors.verticalCenter: parent.verticalCenter

            Icon {
                name: island.sinkReady && island.sink.audio.muted
                    ? "volumeMute"
                    : (island.isHeadphoneNode(island.sink) ? "headphones" : "volumeHigh")
                size: 14
                tint: Theme.text
                anchors.verticalCenter: parent.verticalCenter
            }
            Text {
                text: island.sinkReady ? Math.round(island.sink.audio.volume * 100) + "%" : "—"
                color: Theme.text
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSizeNormal
                anchors.verticalCenter: parent.verticalCenter
            }
        }

        MouseArea {
            anchors.fill: parent
            anchors.margins: -4
            acceptedButtons: Qt.LeftButton | Qt.MiddleButton
            cursorShape: Qt.PointingHandCursor
            onClicked: mouse => {
                if (mouse.button === Qt.MiddleButton) {
                    if (island.sinkReady) island.sink.audio.muted = !island.sink.audio.muted;
                } else {
                    PopupState.toggle("audio");
                }
            }
            onWheel: wheel => {
                if (!island.sinkReady) return;
                const delta = wheel.angleDelta.y > 0 ? 0.05 : -0.05;
                island.sink.audio.volume = Math.max(0, Math.min(1, island.sink.audio.volume + delta));
            }
        }
    }

    Item {
        width: powerIcon.width
        height: powerIcon.height
        anchors.verticalCenter: parent.verticalCenter

        Icon { id: powerIcon; name: "power"; size: 14; tint: Theme.text }

        MouseArea {
            anchors.fill: parent
            anchors.margins: -4
            cursorShape: Qt.PointingHandCursor
            onClicked: PopupState.toggle("power")
        }
    }

    Component {
        id: audioPopupComponent
        AudioPopup {}
    }
    Component {
        id: powerPopupComponent
        PowerPopup {}
    }
}
