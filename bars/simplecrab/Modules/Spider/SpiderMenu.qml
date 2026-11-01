import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import "../.."
import "Figures"

// Popup-Menue fuer den Spinnen-Modus, optisch identisch zum Rest der Bar
// (gleiches Muster wie Modules/Bar/PowerMenu.qml: eigene kleine Overlay-
// Layer-Surface statt In-Bar-Popup, spannt transparent den ganzen
// Bildschirm auf, Klick auf den Rand schliesst). Ueberwiegend maus-/
// beruehrungsgesteuert (Joystick ziehen, Slider ziehen, Schalter klicken),
// braucht aber Escape zum Schliessen -- deshalb WlrKeyboardFocus.OnDemand
// statt None. Ueber SpiderTrigger.qml per LazyLoader bei jedem Oeffnen
// frisch erzeugt, genau wie Launcher.qml -- mango vergibt einer OnDemand-
// Surface Keyboard-Fokus nur bei deren allererstem Commit (siehe dortiger
// Kommentar), eine wiederverwendete Surface bekaeme ihn nie zuverlaessig.
PanelWindow {
    id: root

    required property ShellScreen screen
    signal dismissed

    anchors {
        top: true
        left: true
        right: true
        bottom: true
    }
    color: "transparent"

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "simplecrab-spidermenu"
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand

    MouseArea {
        anchors.fill: parent
        onClicked: root.dismissed()
    }

    // Tastatureingabe braucht ein fokussiertes Item, nicht Keys direkt am
    // Fenster (gleiches Muster wie SearchField.qml/SpiderOverlay.qml).
    Item {
        anchors.fill: parent
        focus: true

        Component.onCompleted: forceActiveFocus()

        Keys.onEscapePressed: root.dismissed()
    }

    Rectangle {
        id: box
        anchors.top: parent.top
        anchors.right: parent.right
        anchors.topMargin: Settings.barHeight + 4
        anchors.rightMargin: 8
        width: Settings.spiderMenuWidth
        height: content.implicitHeight + 24
        radius: 8
        color: Colors.panel

        // Absorbiert Klicks auf den Menue-Hintergrund, damit sie nicht als
        // "Klick ausserhalb" bei der Vollbild-MouseArea darunter zaehlen.
        MouseArea {
            anchors.fill: parent
            onClicked: {}
        }

        ColumnLayout {
            id: content
            anchors.fill: parent
            anchors.margins: 12
            spacing: 14

            RowLayout {
                Layout.fillWidth: true

                Text {
                    text: "Spinnen-Modus"
                    color: Colors.text
                    font.family: Colors.fontFamily
                    font.pointSize: Colors.fontSize
                    font.letterSpacing: Colors.letterSpacing
                    Layout.fillWidth: true
                }

                SpiderToggle {
                    checked: SpiderState.enabled
                    onToggled: checked => SpiderState.setEnabled(checked)
                }
            }

            SpiderJoystick {
                Layout.alignment: Qt.AlignHCenter
                Layout.topMargin: 2
                Layout.bottomMargin: 2
                joystickEnabled: SpiderState.enabled
                onVectorChanged: (vx, vy) => SpiderController.setJoystick(vx, vy)
            }

            SpiderSlider {
                Layout.fillWidth: true
                label: "Geschwindigkeit"
                unit: "px/s"
                from: Settings.spiderSpeedMin
                to: Settings.spiderSpeedMax
                value: SpiderState.speed
                onMoved: v => SpiderState.setSpeed(v)
            }

            SpiderSlider {
                Layout.fillWidth: true
                label: "Groesse"
                unit: "px"
                from: Settings.spiderSizeMin
                to: Settings.spiderSizeMax
                value: SpiderState.size
                onMoved: v => SpiderState.setSize(v)
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 4

                Text {
                    text: "Figur"
                    color: Colors.textDim
                    font.family: Colors.fontFamily
                    font.pointSize: Colors.fontSize - 1
                }

                Repeater {
                    model: FigureRegistry.figures

                    delegate: Rectangle {
                        id: figureRow
                        required property var modelData

                        Layout.fillWidth: true
                        height: 28
                        radius: 4
                        color: figureRow.modelData.id === SpiderState.figureId ? Colors.panelAlt : "transparent"

                        Text {
                            anchors.left: parent.left
                            anchors.leftMargin: 8
                            anchors.verticalCenter: parent.verticalCenter
                            text: figureRow.modelData.name
                            color: figureRow.modelData.id === SpiderState.figureId ? Colors.accent : Colors.text
                            font.family: Colors.fontFamily
                            font.pointSize: Colors.fontSize
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: SpiderState.setFigureId(figureRow.modelData.id)
                        }
                    }
                }
            }
        }
    }
}
