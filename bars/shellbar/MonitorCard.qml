import QtQuick
import QtQuick.Layouts

// One CPU/RAM/GPU card in SettingsMenu's Monitor tab: label + live value on
// top, a rolling HistoryChart underneath.
Rectangle {
    id: card

    property string label: ""
    property real percent: 0
    property string valueText: ""
    property var history: []

    Layout.fillWidth: true
    radius: 12
    color: Qt.alpha(Theme.mutedText, 0.07)
    implicitHeight: cardCol.implicitHeight + 20

    ColumnLayout {
        id: cardCol
        anchors.fill: parent
        anchors.margins: 10
        spacing: 6

        RowLayout {
            Layout.fillWidth: true
            Text { text: card.label; color: Theme.foreground; font.pixelSize: 13; font.bold: true; Layout.fillWidth: true }
            Text {
                text: card.valueText.length > 0 ? card.valueText : Math.round(card.percent) + "%"
                color: Theme.accent
                font.pixelSize: 13
                font.bold: true
            }
        }

        HistoryChart {
            Layout.fillWidth: true
            Layout.preferredHeight: 46
            history: card.history
            color: Theme.accent
        }
    }
}
