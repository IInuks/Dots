import QtQuick
import Quickshell
import Quickshell.Wayland
import "../.."
import "Figures"

// Overlay-Fenster fuer den aktiven Spinnen-Modus. Wird AUSSCHLIESSLICH ueber
// einen LazyLoader in shell.qml erzeugt/zerstoert (active: SpiderState.enabled)
// -- kein dauerhaftes Fenster, dessen keyboardFocus nur umgeschaltet wird.
//
// Grund, konkret: mango vergibt einer Layer-Surface Keyboard-Fokus laut
// eigenem Quellcode (focuslayer(), aufgerufen aus commitlayersurfacenotify's
// initial_commit-Zweig und aus dem Pointer-Button-Handler) nur beim
// allerersten Commit einer Surface oder -- nur fuer Surfaces, die schon
// OnDemand sind -- bei einem Mausklick, der VOR dem fokusaendernden Commit
// verarbeitet wird. Ein Umschalten von WlrKeyboardFocus auf einer
// langlebigen, wiederverwendeten Surface gewinnt den Fokus dadurch nicht
// zuverlaessig -- weder per Klick (der oeffnende Klick selbst kommt vor dem
// Commit an) noch per IPC/Hotkey (da gibt es gar keinen Klick). Da dieses
// Fenster bei jeder Aktivierung frisch erzeugt wird, ist keyboardFocus
// unten FEST auf Exclusive gesetzt (keine Bindung an einen sich aendernden
// Zustand) -- das garantiert den Fokusgewinn beim initial_commit, egal ob
// der Modus per Menue-Schalter, Hotkey oder sonstwie eingeschaltet wurde.
// Ausschalten zerstoert dieses Fenster komplett ueber denselben LazyLoader
// -- der Fokus ist danach strukturell weg, nicht nur "sollte eigentlich".
// Solange der Modus aus ist, existiert dieses Fenster gar nicht -- die
// Shell kann in dem Zustand also unter keinen Umstaenden Tastaturfokus
// greifen, siehe auch dortigen Test in der README.
PanelWindow {
    id: root

    required property ShellScreen screen

    anchors {
        top: true
        left: true
        right: true
        bottom: true
    }
    color: "transparent"

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "simplecrab-spider-overlay"
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

    // Komplett klick-durchlaessig: eine leere Region statt der vollen
    // Fenstergroesse. Ohne das wuerde diese bildschirmfuellende Surface
    // trotz transparenter Darstellung jeden Klick im ganzen Bildschirm
    // schlucken (siehe Projektnotizen zu PanelWindow-Input-Masken) -- der
    // echte Mauszeiger bleibt dadurch normal benutzbar, waehrend die Figur
    // laeuft. Betrifft nur Pointer/Touch, keine Tastatur -- die Keys-Handler
    // unten funktionieren trotzdem.
    mask: Region {}

    Component.onCompleted: SpiderController.start(root.screen)
    Component.onDestruction: SpiderController.stop()

    // Tastatureingabe braucht ein fokussiertes Item, nicht Keys direkt am
    // Fenster (gleiches Muster wie Modules/Launcher/SearchField.qml, das
    // hier nachweislich funktioniert) -- forceActiveFocus() beim Erzeugen,
    // da diese Surface ja sowieso jedes Mal frisch entsteht.
    Item {
        id: inputCapture
        anchors.fill: parent
        focus: true

        Component.onCompleted: forceActiveFocus()

        Keys.onPressed: event => root._handleKey(event, true)
        Keys.onReleased: event => root._handleKey(event, false)
    }

    function _handleKey(event, pressed) {
        switch (event.key) {
        case Qt.Key_W:
        case Qt.Key_Up:
            SpiderController.keyUp = pressed;
            event.accepted = true;
            break;
        case Qt.Key_S:
        case Qt.Key_Down:
            SpiderController.keyDown = pressed;
            event.accepted = true;
            break;
        case Qt.Key_A:
        case Qt.Key_Left:
            SpiderController.keyLeft = pressed;
            event.accepted = true;
            break;
        case Qt.Key_D:
        case Qt.Key_Right:
            SpiderController.keyRight = pressed;
            event.accepted = true;
            break;
        case Qt.Key_Space:
            if (pressed)
                SpiderController.pressClick();
            event.accepted = true;
            break;
        case Qt.Key_Return:
        case Qt.Key_Enter:
            if (pressed)
                SpiderController.closeUnderneath();
            event.accepted = true;
            break;
        case Qt.Key_Escape:
            if (pressed)
                SpiderState.setEnabled(false);
            event.accepted = true;
            break;
        }
    }

    FigureView {
        figureId: SpiderState.figureId
        size: SpiderState.size
        heading: SpiderController.heading
        moving: SpiderController.moving
        x: SpiderController.x - size / 2
        y: SpiderController.y - size / 2
    }
}
