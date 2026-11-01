import QtQuick
import Quickshell
import Quickshell.Wayland

// Anordnen-Modus: ein kleiner Tropfen unter der Leiste mit
//   Zurücksetzen (auf die gespeicherte Anordnung) · Löschen (gespeicherte
//   Anordnung weg, zurück zum Standard) · Speichern · Fertig
// Die Perlen selbst zieht man direkt in der Leiste (Bead.qml / Bar.qml).
PanelWindow {
    id: win
    required property var modelData
    screen: modelData

    visible: Arrange.editing || card.opacity > 0.01
    anchors.top: true
    margins.top: 10
    exclusiveZone: 0
    implicitWidth: card.width + 20
    implicitHeight: card.height + 20
    color: "transparent"
    WlrLayershell.namespace: "drop-arrange"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: Arrange.editing ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

    component Btn: Chip {
        property bool on: true
        enabled: on
        opacity: on ? 1 : 0.35
        Behavior on opacity { NumberAnimation { duration: Theme.tFast } }
    }

    Item {
        anchors.fill: parent
        focus: true
        Keys.onEscapePressed: Arrange.finish()

        Rectangle {
            id: card
            x: 10
            width: content.implicitWidth + 2 * Theme.pad
            height: content.implicitHeight + 2 * 12
            radius: height / 2
            border.width: 1
            border.color: Theme.alpha(Theme.accent, 0.5)
            opacity: Arrange.editing ? Settings.data.opacity : 0
            y: Arrange.editing ? 0 : -16
            scale: Arrange.editing ? 1 : 0.85
            gradient: Gradient {
                GradientStop { position: 0; color: Theme.water }
                GradientStop { position: 1; color: Theme.waterDeep }
            }
            Behavior on opacity { NumberAnimation { duration: Theme.tMed } }
            Behavior on y { NumberAnimation { duration: Theme.tMed; easing.type: Easing.OutBack } }
            Behavior on scale { NumberAnimation { duration: Theme.tMed; easing.type: Easing.OutBack } }

            Row {
                id: content
                anchors.centerIn: parent
                spacing: 8

                Icon { anchors.verticalCenter: parent.verticalCenter; name: "drag"; size: 18; color: Theme.accent }
                Column {
                    anchors.verticalCenter: parent.verticalCenter
                    Label { text: "Perlen ziehen"; size: 13; bold: true }
                    Label {
                        text: Arrange.dirty ? "nicht gespeichert · aneinander = verschmolzen"
                            : (Arrange.hasSaved ? "gespeichert · aneinander = verschmolzen" : "Standard · aneinander = verschmolzen")
                        size: 11; color: Arrange.dirty ? Theme.warn : Theme.textFaint
                    }
                }
                Item { width: 8; height: 1 }
                Btn {
                    anchors.verticalCenter: parent.verticalCenter
                    text: "Zurücksetzen"; icon: "undo"
                    on: Arrange.dirty
                    onClicked: Arrange.revert()
                }
                Btn {
                    anchors.verticalCenter: parent.verticalCenter
                    text: "Löschen"; icon: "trash"
                    on: Arrange.hasSaved || Arrange.dirty
                    onClicked: Arrange.remove()
                }
                Btn {
                    anchors.verticalCenter: parent.verticalCenter
                    text: "Speichern"; icon: "save"
                    on: Arrange.dirty
                    selected: Arrange.dirty
                    onClicked: Arrange.save()
                }
                Btn {
                    anchors.verticalCenter: parent.verticalCenter
                    text: "Fertig"; icon: "check"
                    onClicked: Arrange.finish()
                }
            }
        }
    }
}
