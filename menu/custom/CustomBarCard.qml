import QtQuick
import ".."

// One saved custom bar in the "Eigene" overview grid -- mini preview (via
// the same BarTheme every other card uses, since adapters/custom-<slug>.json
// is written for it just like a hand-built bar), name, edit/delete.
Rectangle {
    id: card

    property string slug: ""
    property string barName: ""

    signal editRequested()
    signal deleteRequested()

    readonly property BarTheme theme: BarTheme { barName: "custom-" + card.slug }

    width: 168
    height: 110
    radius: 12
    color: Qt.rgba(1, 1, 1, 0.04)

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: card.editRequested()
    }

    Column {
        anchors.fill: parent
        anchors.margins: 10
        spacing: 6

        Rectangle {
            width: parent.width
            height: 44
            radius: 8
            color: Qt.rgba(Qt.color(theme.surface).r, Qt.color(theme.surface).g, Qt.color(theme.surface).b, theme.barOpacity)
            border.width: 2
            border.color: theme.accent
        }

        Text {
            text: card.barName
            color: Theme.foreground
            font.pixelSize: 13
            font.bold: true
            elide: Text.ElideRight
            width: parent.width
        }

        Row {
            spacing: 10

            Text {
                text: "✎ Bearbeiten"
                font.pixelSize: 11
                color: Theme.accent
                MouseArea {
                    anchors.fill: parent
                    anchors.margins: -4
                    cursorShape: Qt.PointingHandCursor
                    onClicked: card.editRequested()
                }
            }

            Text {
                id: deleteLabel
                property bool confirming: false
                text: confirming ? "sicher?" : "🗑"
                font.pixelSize: 11
                color: confirming ? "#ff8080" : Qt.rgba(Theme.foreground.r, Theme.foreground.g, Theme.foreground.b, 0.6)

                Timer { id: resetTimer; interval: 2500; onTriggered: deleteLabel.confirming = false }

                MouseArea {
                    anchors.fill: parent
                    anchors.margins: -4
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (deleteLabel.confirming) {
                            deleteLabel.confirming = false;
                            card.deleteRequested();
                        } else {
                            deleteLabel.confirming = true;
                            resetTimer.restart();
                        }
                    }
                }
            }
        }
    }
}
