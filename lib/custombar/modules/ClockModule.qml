import QtQuick

// Self-contained clock -- no external service, no bar-specific Theme
// singleton. Every custom-bar module follows this same property contract
// (foreground/accent/fontFamily/fontSize/settings) so ZoneContent.qml can
// instantiate any of them identically via Loader.setSource.
Item {
    id: root

    property color foreground: "#e8e8f0"
    property color accent: "#5b8cff"
    property string fontFamily: "monospace"
    property int fontSize: 13
    property var settings: ({})

    readonly property string format: settings.format || "HH:mm"

    implicitWidth: label.implicitWidth
    implicitHeight: label.implicitHeight

    Text {
        id: label
        anchors.centerIn: parent
        color: root.foreground
        font.family: root.fontFamily
        font.pixelSize: root.fontSize
    }

    Timer {
        interval: 1000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: label.text = Qt.formatDateTime(new Date(), root.format)
    }
}
