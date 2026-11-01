import QtQuick

// Uhrzeit + kurzes Datum. Die Ziffern kippen beim Wechsel nach oben weg.
Row {
    id: root
    spacing: 8
    property date now: new Date()
    Timer {
        interval: Settings.data.showSeconds ? 1000 : 10000
        running: true; repeat: true; triggeredOnStart: true
        onTriggered: root.now = new Date()
    }
    readonly property string time: Qt.formatTime(now, Settings.data.showSeconds ? "HH:mm:ss" : "HH:mm")

    Item {
        width: timeA.implicitWidth; height: 20
        clip: true
        anchors.verticalCenter: parent.verticalCenter
        Label {
            id: timeA
            text: root.time
            size: 14.5; bold: true
            font.family: Theme.mono
            font.features: { "tnum": 1 }
            onTextChanged: if (Theme.motion && !Settings.data.showSeconds) flip.restart()
            NumberAnimation on y { id: flip; from: 14; to: 0; duration: Theme.tMed; easing.type: Easing.OutBack; running: false }
        }
    }
    Label {
        anchors.verticalCenter: parent.verticalCenter
        text: root.now.toLocaleDateString(Qt.locale("de_DE"), "ddd, d. MMM")
        size: 12.5
        color: Theme.textDim
    }
}
