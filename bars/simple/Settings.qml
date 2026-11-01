pragma Singleton
import QtQuick

// Root-Singleton aus demselben Grund wie Colors.qml -- siehe dortigen
// Kommentar zum Cross-Directory-Import-Verhalten von pragma-Singleton in
// dieser Quickshell-Version.
QtObject {
    // ---- Bar -------------------------------------------------------
    readonly property int barHeight: 34
    readonly property int workspaceCount: 6
    readonly property int windowTitleMaxLength: 60
    readonly property int rightClusterSpacing: 18

    // ---- Uhr ---------------------------------------------------------
    // Zwei Leerzeichen zwischen Datum und Uhrzeit sind hier bewusst Teil
    // des Formatstrings (kein Format-Token an dieser Stelle). HH = 24h.
    readonly property string clockFormat: "d MMM  HH:mm"

    // ---- MPRIS -------------------------------------------------------
    readonly property int trackTitleMaxLength: 28

    // ---- Lautstaerke (Pipewire) ---------------------------------------
    readonly property real volumeStep: 0.05

    // ---- Benachrichtigungen -------------------------------------------
    // Laufzeit-Zustand (kein readonly, da per Klick umgeschaltet). Quickshell
    // besitzt keinen globalen DND-Schalter -- dieses Flag ist reine
    // UI-Zustandsablage fuer das Glocken-Icon.
    property bool dndEnabled: false

    // ---- Launcher ------------------------------------------------------
    readonly property int launcherWidth: 460
    readonly property int launcherHeight: 520
    readonly property int launcherRadius: 8
    readonly property int launcherRowHeight: 57
    readonly property int launcherRowPadding: 20
    readonly property int launcherAnimationMs: 120
    readonly property string launcherStateFile: "launcher.json"

    // ---- Power-Menu Geometrie ---------------------------------------------
    readonly property int powerMenuWidth: 150
    readonly property int powerMenuItemHeight: 32

    // ---- Power-Menu Kommandos -------------------------------------------
    readonly property string lockCommand: "swaylock"
    readonly property string logoutCommand: "mmsg dispatch quit"
    readonly property string rebootCommand: "systemctl reboot"
    readonly property string shutdownCommand: "systemctl poweroff"
}
