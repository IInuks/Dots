import QtQuick
import QtQuick.Layouts
import "../.."

// Suchfeld: Lupen-Icon links, TextInput daneben, kein Rahmen.
Item {
    id: root

    property alias text: input.text
    signal navigateUp
    signal navigateDown
    signal activateSelected
    signal cancelled

    implicitHeight: 40

    function focusInput() {
        input.forceActiveFocus();
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: Settings.searchRowPadding
        anchors.rightMargin: Settings.searchRowPadding
        spacing: 10

        Text {
            text: "" // nf-fa-search
            color: Colors.accentAlt
            font.family: Colors.fontFamily
            font.pointSize: Colors.fontSize
            Layout.alignment: Qt.AlignVCenter
        }

        TextInput {
            id: input

            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter
            font.family: Colors.fontFamily
            font.pointSize: Colors.fontSize
            font.letterSpacing: Colors.letterSpacing
            color: Colors.text
            selectByMouse: true
            clip: true

            Keys.onUpPressed: root.navigateUp()
            Keys.onDownPressed: root.navigateDown()
            Keys.onEscapePressed: root.cancelled()
            Keys.onReturnPressed: root.activateSelected()
            Keys.onPressed: event => {
                if (event.modifiers & Qt.ControlModifier) {
                    if (event.key === Qt.Key_J) {
                        root.navigateDown();
                        event.accepted = true;
                    } else if (event.key === Qt.Key_K) {
                        root.navigateUp();
                        event.accepted = true;
                    }
                }
            }
        }
    }
}
