pragma Singleton
import QtQuick

// Root-Singleton aus demselben Grund wie Colors.qml -- siehe dortigen
// Kommentar zum Cross-Directory-Import-Verhalten von pragma-Singleton in
// dieser Quickshell-Version.
QtObject {
    // ---- Notch (EIN Fenster, das sich zwischen Pille und Karte/Suche/
    // Wallpaper-Grid verformt -- kein separates Popup-Fenster mehr fuer
    // Launcher/Wallpaper, siehe Notch.qml) -----------------------------------
    // Kollabiert: nur die Uhr, Hoehe notchCollapsedHeight, Breite folgt dem
    // Uhr-Text. "settings"-Subview: feste Breite notchExpandedWidth, Hoehe
    // folgt dem Inhalt. "search"/"wallpaper"-Subviews: eigene feste
    // Zielgroessen (searchWidth/Height, wallpaperWidth/Height) -- das
    // *ist* das "Verformen": dieselbe Surface animiert zwischen allen
    // Groessen, nie ein zweites Fenster. radius bleibt uebergreifend
    // konstant -- bei collapsedHeight sieht das wie eine Pille aus
    // (radius ~= height/2), bei jeder groesseren Form wie eine abgerundete
    // Karte; ein von der animierten Hoehe abgeleiteter Radius wuerde bei
    // Zwischenwerten der Groessen-Animation unproportioniert wirken.
    readonly property int notchCollapsedHeight: 36
    readonly property int notchExpandedWidth: 420
    readonly property int notchRadius: 18
    readonly property int notchMarginTop: 8
    readonly property int notchPadding: 18
    readonly property int notchRowSpacing: 12
    readonly property int notchSectionSpacing: 16
    readonly property int notchAnimationMs: 260
    readonly property int notchCloseDelayMs: 350
    // Reservierte Zone am oberen Bildschirmrand (siehe TopGapReserve.qml):
    // haelt getilte Fenster unterhalb der kollabierten Pille + etwas Luft,
    // statt dass sie direkt bis an den Notch heranreichen/darunter liegen.
    readonly property int notchTopReserveZone: notchMarginTop + notchCollapsedHeight + 6

    readonly property int workspaceCount: 6
    readonly property int windowTitleMaxLength: 60

    // ---- Uhr ---------------------------------------------------------
    readonly property string clockFormat: "d MMM  HH:mm"
    readonly property string clockFormatCollapsed: "HH:mm"

    // ---- MPRIS -------------------------------------------------------
    readonly property int trackTitleMaxLength: 28

    // ---- Lautstaerke/Mikrofon (Pipewire) ---------------------------------
    readonly property real volumeStep: 0.05
    readonly property int sliderHeight: 6
    readonly property int toggleWidth: 36
    readonly property int toggleHeight: 20

    // ---- Netzwerk (NetworkManager) ---------------------------------------
    readonly property string wifiToggleOnCommand: "nmcli radio wifi on"
    readonly property string wifiToggleOffCommand: "nmcli radio wifi off"
    readonly property string wifiStatusCommand: "nmcli -t -f WIFI radio"

    // ---- Screenshot --------------------------------------------------------
    readonly property string screenshotCommand: "flameshot gui"

    // ---- Benachrichtigungen -------------------------------------------
    // Laufzeit-Zustand (kein readonly, per Klick im Notch umgeschaltet).
    // Quickshell besitzt keinen globalen DND-Schalter -- dieses Flag ist
    // reine UI-Zustandsablage.
    property bool dndEnabled: false

    // ---- Suche (Subview "search", ersetzt das fruehere eigene
    // Launcher-Fenster) ---------------------------------------------------
    // Gleiche Breite wie die "settings"-Karte -- beim Wechsel dorthin
    // verformt sich nur die Hoehe, nicht die Breite, das wirkt ruhiger als
    // ein Sprung in beiden Dimensionen gleichzeitig.
    readonly property int searchWidth: notchExpandedWidth
    readonly property int searchHeight: 440
    readonly property int searchRowHeight: 52
    readonly property int searchRowPadding: 16
    readonly property string launcherStateFile: "launcher.json"

    // ---- Power-Aktionen (als Icon-Reihe in der "settings"-Karte, kein
    // eigenes Untermenue) -------------------------------------------------
    readonly property string lockCommand: "swaylock"
    readonly property string logoutCommand: "mmsg dispatch quit"
    readonly property string rebootCommand: "systemctl reboot"
    readonly property string shutdownCommand: "systemctl poweroff"

    // ---- Wallpaper (Subview "wallpaper", ersetzt das fruehere eigene
    // WallpaperPicker-Fenster) -----------------------------------------------
    // Hinweis: der tatsaechliche Ordner heisst "Walpapers" (Tippfehler,
    // konsistent mit ~/quickdots/shellwall/Config.qml -- absichtlich nicht
    // "korrigiert", damit beide Tools denselben realen Pfad treffen).
    readonly property string wallpaperDir: "Pictures/Walpapers"
    readonly property var wallpaperExtensions: ["jpg", "jpeg", "png", "webp"]
    // "awww" = Nixpkgs-Umbenennung von "swww", CLI ist 1:1 identisch
    // geblieben (siehe ~/quickdots/shellwall/Config.qml).
    readonly property string wallpaperBinary: "awww"
    readonly property string wallpaperTransitionType: "any"
    readonly property int wallpaperTransitionFps: 60
    readonly property bool wallpaperRunPywal: true

    // Breiter als die "settings"/"search"-Breite -- das Grid braucht den
    // Platz, und die Breiten-Aenderung selbst ist Teil des "Verformens",
    // nicht etwas, das vermieden werden muss.
    readonly property int wallpaperWidth: 620
    readonly property int wallpaperHeight: 460
    readonly property int wallpaperTileWidth: 178
    readonly property int wallpaperTileHeight: 108
    readonly property int wallpaperTileSpacing: 10
    readonly property int wallpaperTileRadius: 6
}
