import QtQuick
import "../core"
import "../fold"

// Faecher: die Papiersorten stecken als Musterstreifen an einer Niete und
// spreizen sich beim Oeffnen nach oben auf (wie ein Farbfaecher). Hover schiebt einen Streifen heraus,
// Klick waehlt das Papier -- die Leiste blaettert dann um.
Menu {
    id: m
    menuId: "paper"
    width: 560
    height: 384
    openDuration: 620
    closeDuration: 360

    readonly property int count: Paper.order.length
    readonly property real spread: 24
    readonly property real bladeLen: 270
    readonly property real pivotX: width / 2
    readonly property real pivotY: height - 58

    Repeater {
        model: Paper.order
        delegate: Item {
            id: blade
            required property string modelData
            required property int index
            readonly property var pal: Paper.palettes[modelData]
            readonly property bool current: Paper.name === modelData
            readonly property bool hot: area.containsMouse
            // gestaffelt: aeussere Streifen etwas spaeter
            readonly property real local: Math.max(0, Math.min(1, m.progress * 1.25 - Math.abs(index - (m.count - 1) / 2) * 0.08))

            z: hot ? 10 : index
            x: m.pivotX - width / 2
            y: m.pivotY - m.bladeLen + 14
            width: 64
            height: m.bladeLen
            transformOrigin: Item.Bottom
            rotation: (index - (m.count - 1) / 2) * m.spread * local
            opacity: Math.min(1, m.progress * 3)
            scale: 0.85 + 0.15 * m.progress

            property real push: hot ? 16 : (current ? 8 : 0)
            Behavior on push { NumberAnimation { duration: 260; easing.type: Easing.OutBack } }

            Item {
                y: -blade.push
                width: parent.width
                height: parent.height

                Sheet {
                    anchors.fill: parent
                    tint: blade.pal.paper
                    radius: 8
                    lift: blade.hot ? 2 : 1
                    border.color: Qt.darker(blade.pal.paper, blade.pal.dark ? 1.4 : 1.15)

                    // Farbfelder wie auf einer Musterkarte
                    Column {
                        x: 8
                        y: 10
                        width: parent.width - 16
                        spacing: 4
                        Repeater {
                            model: [blade.pal.accent, blade.pal.second, blade.pal.ink]
                            delegate: Rectangle {
                                required property color modelData
                                width: parent.width
                                height: 22
                                radius: 3
                                color: modelData
                            }
                        }
                        Rectangle {
                            width: parent.width
                            height: 22
                            radius: 3
                            color: blade.pal.deep
                        }
                    }

                    Text {
                        // Name laengs des Streifens
                        x: parent.width / 2 - width / 2
                        y: 178 - height / 2
                        width: 130
                        horizontalAlignment: Text.AlignHCenter
                        rotation: -90
                        text: blade.pal.title
                        font.family: Paper.serif
                        font.pixelSize: 15
                        font.bold: true
                        color: blade.pal.ink
                    }

                    // adaptiv: kleines Bild-Symbol unten am Streifen
                    Text {
                        visible: blade.modelData === "adaptiv"
                        anchors.horizontalCenter: parent.horizontalCenter
                        y: parent.height - 34
                        text: ""
                        font.family: Paper.mono
                        font.pixelSize: 15
                        color: blade.pal.accent
                    }

                    // Stempel "gewaehlt"
                    Rectangle {
                        visible: blade.current
                        anchors.horizontalCenter: parent.horizontalCenter
                        y: 120
                        width: 26
                        height: 26
                        radius: 13
                        color: "transparent"
                        border.width: 2
                        border.color: blade.pal.accent
                        rotation: -14
                        Text {
                            anchors.centerIn: parent
                            text: "✓"
                            font.pixelSize: 15
                            font.bold: true
                            color: blade.pal.accent
                        }
                    }
                }
            }

            MouseArea {
                id: area
                y: -blade.push
                width: parent.width
                height: parent.height - 40
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                enabled: m.shown
                onClicked: Paper.request(blade.modelData)
            }
        }
    }

    // Niete
    Rectangle {
        x: m.pivotX - 9
        y: m.pivotY - 9
        width: 18
        height: 18
        radius: 9
        color: Paper.ink
        opacity: m.progress
        border.width: 3
        border.color: Paper.accent
        z: 20
    }

    Text {
        anchors.horizontalCenter: parent.horizontalCenter
        y: m.pivotY + 44
        opacity: m.progress
        text: Paper.p.note
        font.family: Paper.serif
        font.italic: true
        font.pixelSize: 13
        color: Paper.dark ? Paper.ink : "#ffffff"
        style: Text.Outline
        styleColor: Paper.dark ? "#000000" : Paper.ink
    }
}
