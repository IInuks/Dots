pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Persistierte Spinnen-Modus-Einstellungen. Root-Singleton aus demselben
// Grund wie Colors.qml (pragma-Singleton loest in dieser Quickshell-Version
// nur ueber denselben Ordner oder eine reine ".."-Elternkette auf).
//
// Folgt demselben Muster wie bars/shellbar/ChessState.qml: FileView mit
// JsonAdapter, "onLoaded" kopiert in gewoehnliche root-Properties (der Rest
// der Bar bindet auf die, nicht auf adapter.* direkt), jede setXxx()-
// Funktion schreibt beides, "onAdapterUpdated: writeAdapter()" persistiert
// automatisch bei jeder Aenderung.
//
// Achtung, bewusst so gewaehlt: "enabled" ist Teil der persistierten Werte
// (wie gewuenscht -- "alle Einstellungen"), d.h. ein Shell-Neustart bei
// aktivem Modus aktiviert ihn sofort wieder MIT sofortigem exklusivem
// Tastatur-Grab (siehe SpiderOverlay.qml). Falls das ueberrascht: einmal
// Escape druecken.
QtObject {
    id: root

    property bool enabled: false
    property real speed: Settings.spiderSpeedDefault
    property string figureId: "spider"
    property real size: Settings.spiderSizeDefault

    function setEnabled(v) {
        root.enabled = v;
        _file.adapter.enabled = v;
    }
    function setSpeed(v) {
        root.speed = v;
        _file.adapter.speed = v;
    }
    function setFigureId(id) {
        root.figureId = id;
        _file.adapter.figureId = id;
    }
    function setSize(v) {
        root.size = v;
        _file.adapter.size = v;
    }

    property var _file: FileView {
        id: _file
        path: Quickshell.statePath(Settings.spiderStateFile)
        watchChanges: true
        onLoaded: {
            root.enabled = adapter.enabled;
            root.speed = adapter.speed;
            root.figureId = adapter.figureId;
            root.size = adapter.size;
        }
        onAdapterUpdated: writeAdapter()
        adapter: JsonAdapter {
            property bool enabled: false
            property real speed: Settings.spiderSpeedDefault
            property string figureId: "spider"
            property real size: Settings.spiderSizeDefault
        }
    }
}
