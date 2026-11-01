import QtQuick
import "../core"

// Eine Facette des Leporellos: jedes Modul liegt auf einer eigenen
// "Seite" mit Knicklinie links und leichtem Licht-/Schattenverlauf --
// abwechselnd (odd), so dass das Papierstueck wie zickzack-gefaltet wirkt.
Item {
    id: root
    property bool odd: false
    property bool crease: true
    property int pad: 10
    property bool hovered: false
    default property alias inner: lay.data

    implicitWidth: lay.implicitWidth + pad * 2
    implicitHeight: Paper.barHeight

    Rectangle {
        anchors.fill: parent
        anchors.topMargin: 1
        anchors.bottomMargin: 1
        gradient: Gradient {
            orientation: Gradient.Horizontal
            GradientStop { position: 0; color: root.odd ? Qt.rgba(0, 0, 0, Paper.dark ? 0.16 : 0.06) : Qt.rgba(1, 1, 1, Paper.dark ? 0.03 : 0.18) }
            GradientStop { position: 1; color: root.odd ? Qt.rgba(1, 1, 1, Paper.dark ? 0.02 : 0.10) : Qt.rgba(0, 0, 0, Paper.dark ? 0.10 : 0.04) }
        }
    }
    Rectangle {
        anchors.fill: parent
        anchors.margins: 3
        radius: 4
        color: Paper.ink
        opacity: root.hovered ? 0.07 : 0
        Behavior on opacity { NumberAnimation { duration: Paper.tQuick } }
    }
    Rectangle {
        visible: root.crease
        x: 0
        width: 1
        height: parent.height - 2
        y: 1
        color: Qt.darker(Paper.paper, Paper.dark ? 1.6 : 1.14)
    }
    Rectangle {
        visible: root.crease
        x: 1
        width: 1
        height: parent.height - 2
        y: 1
        color: Qt.lighter(Paper.paper, Paper.dark ? 1.25 : 1.04)
        opacity: 0.8
    }

    Row {
        id: lay
        x: root.pad
        anchors.verticalCenter: parent.verticalCenter
        spacing: 6
    }
}
