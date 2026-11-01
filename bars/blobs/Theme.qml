pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Live-Palette aus matugen (Auftrag Abschnitt 8). Root-level Singleton,
// damit jede Datei unter components/ und content/ sie über einen reinen
// ".."-Import erreicht -- ein seitlicher/symlink-Import eines
// pragma-Singleton liefert in dieser Quickshell-Version sonst nur
// undefined-Properties, ohne Fehlermeldung.
QtObject {
    id: root

    // Von ~/.config/matugen/templates/blobs-colors.json geschrieben (siehe
    // ~/.config/matugen/config.toml) -- ein "matugen image <pfad>"-Aufruf
    // setzt darueber auch gleich das Wallpaper (config.wallpaper.command),
    // Theme.qml uebernimmt die neuen Farben automatisch per watchChanges.
    property var _live: ({})

    // Bare "FileView { ... }" waere ein Kind ohne Default-Property auf
    // QtObject und scheitert an "Cannot assign to non-existent default
    // property" -- deshalb als benannte Property wie ueberall sonst in
    // diesem Projekt (Mango.qml, Cpu.qml).
    property FileView colorsFile: FileView {
        id: colorsFile
        path: Quickshell.env("HOME") + "/.cache/blobs-bar/colors.json"
        watchChanges: true
        onLoaded: root._onColorsText(colorsFile.text())
        onFileChanged: colorsFile.reload()
    }

    function _onColorsText(text) {
        try {
            root._live = JSON.parse(text);
        } catch (e) {
            root._live = {};
        }
    }

    // Fallback, solange colors.json (noch) nicht existiert (vor dem ersten
    // Wallpaper-Wechsel) oder kaputt ist.
    readonly property color _fallbackBackground: "#14151a"
    readonly property color _fallbackSurface: "#1f2128"
    // "on"-Praefix vermieden (surfaceInk statt onSurface): ein Property-Name
    // nach dem Muster /^on[A-Z]/ wird von QML als Signal-Handler-Deklaration
    // gelesen, nicht als Property -- "Cannot assign a value to a signal".
    readonly property color _fallbackSurfaceInk: "#e3e2e6"
    readonly property color _fallbackPrimary: "#8ab4f8"
    readonly property color _fallbackPrimaryInk: "#00315c"
    readonly property color _fallbackOutline: "#44464f"
    readonly property color _fallbackCritical: "#ff6b6b"

    property color background: root._live.background || root._fallbackBackground
    property color surface: root._live.surface || root._fallbackSurface
    property color surfaceInk: root._live.surfaceInk || root._fallbackSurfaceInk
    property color primary: root._live.primary || root._fallbackPrimary
    property color primaryInk: root._live.primaryInk || root._fallbackPrimaryInk
    property color outline: root._live.outline || root._fallbackOutline
    property color critical: root._live.critical || root._fallbackCritical

    // Farbwechsel animiert, ~300ms (Auftrag Abschnitt 8), damit ein
    // Wallpaper-Wechsel weich wirkt statt umzuspringen.
    Behavior on background {
        ColorAnimation {
            duration: 300
        }
    }
    Behavior on surface {
        ColorAnimation {
            duration: 300
        }
    }
    Behavior on surfaceInk {
        ColorAnimation {
            duration: 300
        }
    }
    Behavior on primary {
        ColorAnimation {
            duration: 300
        }
    }
    Behavior on primaryInk {
        ColorAnimation {
            duration: 300
        }
    }
    Behavior on outline {
        ColorAnimation {
            duration: 300
        }
    }
    Behavior on critical {
        ColorAnimation {
            duration: 300
        }
    }

    // Temperaturring-Farbstufen (Auftrag Abschnitt 6: gruen bis 65°C, amber
    // bis 80°C, darueber "critical" oben) -- bewusst nicht aus matugen,
    // brauchen feste Bedeutung (gut/warnung) unabhaengig von der Palette.
    readonly property color tempGood: "#7ee08a"
    readonly property color tempWarn: "#f0b955"

    readonly property int barHeight: 46
    readonly property int pillWidth: 118
    readonly property int gap: 12
    readonly property int topMargin: 8
    // Groesste offene Flaeche ueber alle drei Blobs (Auftrag Abschnitt 4:
    // linke Kugel/Wallpaper-Grid ca. 268x256 -- die groesste aller
    // Geoeffnet-Groessen). Bar.qml braucht das Fenster so hoch, sonst
    // wird jeder offene Blob am Fensterrand abgeschnitten; die mask
    // sorgt trotzdem dafuer, dass der Leerraum darunter keine Klicks
    // abfaengt (siehe Bar.qml).
    readonly property int maxPanelHeight: 256

    // Bewegung: einzige Quelle fuer Dauern/Easings (Auftrag Abschnitt 3).
    readonly property int durMorphOpen: 380
    readonly property int durMorphClose: 300
    // Etwas schneller als durMorphOpen, damit die Form frueh "zur Flaeche
    // wird" (Abschnitt 3).
    readonly property int durRadiusOpen: 340
    readonly property int durBodyFadeDelay: 160
    readonly property int durBodyFade: 220
    readonly property int durCrossfade: 180
    // Fuellstand + Farbwechsel des Temperaturrings (Auftrag Abschnitt 6).
    readonly property int durRingFill: 400
    readonly property int easeMorph: Easing.OutCubic
}
