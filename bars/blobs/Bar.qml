import QtQuick
import Quickshell
import Quickshell.Wayland
import "components"

// Ein Fenster pro Bildschirm (Variants in shell.qml instanziiert dies pro
// Monitor).
PanelWindow {
    id: bar

    required property var modelData
    screen: modelData
    readonly property string outputName: bar.screen ? bar.screen.name : ""

    anchors.top: true
    anchors.left: true
    anchors.right: true

    // Reserviert Platz fuer die Ruhezustand-Bar (Nutzerwunsch: echte Gap
    // oben, Fenster sollen nicht unter der Bar liegen) -- nur die
    // Ruhehoehe, nicht Theme.maxPanelHeight, sonst wuerde staendig so viel
    // Platz reserviert wie das groesste offene Panel braucht. Ein offenes
    // Panel waechst trotzdem ungehindert ueber diese Zone hinaus nach unten
    // (schwebt dann ueber Fenstern, wie schon vorher).
    exclusiveZone: Theme.topMargin + Theme.barHeight
    // Hoch genug fuer die groesste offene Menüflaeche (siehe Theme.
    // maxPanelHeight) -- die mask unten sorgt dafuer, dass der Leerraum
    // darunter trotzdem keine Klicks abfaengt, solange nichts offen ist.
    implicitHeight: Theme.topMargin + Theme.maxPanelHeight
    color: "transparent"

    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.namespace: "blobs-bar"
    // Solange irgendein Panel offen ist (nicht nur der Launcher) --
    // Escape soll jedes offene Panel schliessen koennen, nicht nur das
    // Suchfeld. UNVERIFIZIERT bisher: siehe README "Stolperfallen" --
    // Exclusive statt OnDemand auf einer bereits laufenden, wiederverwendeten
    // Surface.
    WlrLayershell.keyboardFocus: BarState.active !== "none" ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    // Blob-Flaechen + der Klick-daneben-Schliessen-Catcher -- nicht die
    // gesamte Fensterhöhe/-breite, sonst faengt der Leerraum darueber/
    // darunter Klicks ab, die eigentlich zum darunterliegenden Fenster
    // gehoeren (siehe outsideCloseArea unten).
    mask: Region {
        Region {
            item: outsideCloseArea
        }
        Region {
            item: leftBlob
        }
        Region {
            item: middleBlob
        }
        Region {
            item: rightBlob
        }
    }

    // Deckt das ganze Fenster ab, aber nur solange irgendetwas offen ist
    // (Hoehe kollabiert sonst auf 0 -- die mask oben liest die echte
    // Geometrie, `visible` allein wuerde die Region nicht schrumpfen, siehe
    // bars/fisheye/bar/Bar.qml fuer denselben Trick). Zuerst deklariert,
    // damit die drei Blobs (spaeter deklariert = oben in der
    // Stapelreihenfolge) bei ueberlappenden Klicks Vorrang haben.
    MouseArea {
        id: outsideCloseArea
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        height: BarState.active !== "none" ? parent.height : 0
        onClicked: BarState.close()
    }

    // PanelWindow selbst hat kein `opacity` -- die drei Blobs stecken
    // deshalb in einem eigenen Item, dessen Opacity der Transparenz-Slider
    // der linken Kugel steuert (Auftrag Abschnitt 4). outsideCloseArea
    // bleibt bewusst ausserhalb: der Klick-Catcher ist ohnehin unsichtbar
    // und soll unabhaengig von der eingestellten Deckkraft funktionieren.
    // Escape soll jedes offene Panel schliessen, nicht nur das Launcher-
    // Suchfeld (das seinen eigenen Keys.onEscapePressed hat und sich beim
    // Oeffnen selbst fokussiert, siehe ClockBlob.qml onModeChanged) --
    // fuer Kalender/Workspace/System/Audio uebernimmt blobsLayer den Fokus.
    Connections {
        target: BarState
        function onActiveChanged() {
            if (BarState.active !== "none" && BarState.active !== "launcher")
                blobsLayer.forceActiveFocus();
        }
    }

    Item {
        id: blobsLayer
        anchors.fill: parent
        opacity: Settings.barOpacity
        focus: true
        Keys.onEscapePressed: BarState.close()

        WorkspaceBlob {
            id: leftBlob
            outputName: bar.outputName
            anchors.top: parent.top
            anchors.topMargin: Theme.topMargin
            anchors.right: middleBlob.left
            anchors.rightMargin: Theme.gap
        }

        ClockBlob {
            id: middleBlob
            outputName: bar.outputName
            anchors.top: parent.top
            anchors.topMargin: Theme.topMargin
            anchors.horizontalCenter: parent.horizontalCenter
        }

        TempBlob {
            id: rightBlob
            anchors.top: parent.top
            anchors.topMargin: Theme.topMargin
            anchors.left: middleBlob.right
            anchors.leftMargin: Theme.gap
        }
    }
}
