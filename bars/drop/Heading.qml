import QtQuick

// Abschnittstitel in den Menüs: kleiner Tropfen + Text.
Row {
    property string text: ""
    spacing: 8
    Droplet { anchors.verticalCenter: parent.verticalCenter; width: 9; height: 12; fill: Theme.accent; shine: false }
    Label { anchors.verticalCenter: parent.verticalCenter; text: parent.text; size: 11.5; bold: true; color: Theme.textDim; font.letterSpacing: 1.2; font.capitalization: Font.AllUppercase }
}
