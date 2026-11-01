import QtQuick
import Quickshell

// Zentrale Konfiguration fuer den Wallpaper-Switcher.
// Alle Werte, die man typischerweise anpassen will, stehen hier gebuendelt.
QtObject {
    id: config

    // --- Wallpaper-Quelle -------------------------------------------------
    // Hinweis: auf diesem System heisst der tatsaechliche Ordner "Walpapers"
    // (Tippfehler, siehe ~/.config/quickshell/quickwall). Passe das hier an,
    // falls du den Ordner umbenennst oder einen anderen Pfad nutzen willst.
    property string wallpaperDir: Quickshell.env("HOME") + "/Pictures/Walpapers"
    property var extensions: ["jpg", "jpeg", "png", "webp"]

    // --- Wallpaper-Backend -------------------------------------------------
    // Hinweis: das nixpkgs-Paket "swww" wurde upstream in "awww" umbenannt
    // (Binary heisst jetzt awww/awww-daemon, CLI ist 1:1 identisch geblieben).
    property string wallpaperBinary: "awww"
    property string transitionType: "any"
    property int transitionFps: 60

    // shellbar's "Adaptive"-Theme (siehe ~/shellbar/Theme.qml) liest
    // ~/.cache/wal/colors.json und braucht dafuer einen pywal-Lauf pro
    // Wallpaper-Wechsel, genau wie quickwall das bisher gemacht hat.
    property bool runPywal: true

    // ricev2's Colors.qml liest ~/.cache/ricev2/colors.json, geschrieben
    // vom "ricev2"-Template in ~/.config/matugen/config.toml. --mode dark
    // + --source-color-index 0 wie in bars/lucid|klasic|rice/Theme.qml
    // (sonst fragt matugen bei mehreren Quellfarben interaktiv nach, was
    // ohne Terminal nur haengt/fehlschlaegt).
    property bool runMatugen: true

    // --- Slice-Geometrie ---------------------------------------------------
    // 1:1 aus quickdots/bars/ricev2/Style.qml uebernommen (Launcher-
    // Slice-Modus, siehe dortiges Bar/launcher/SliceDelegate.qml) --
    // sliceExpandedWidth:sliceHeight (924:520) trifft zufaellig fast exakt
    // 16:9, passt fuer Wallpaper-Vorschauen also sogar besser als fuer den
    // App-Launcher, den es urspruenglich zeigt.
    property int sliceWidth: 135
    property int sliceExpandedWidth: 924
    property int sliceHeight: 520
    property int sliceSkew: 35
    property int sliceSpacing: -22
    property int sliceVisibleCount: 12

    property int thumbSourceWidth: 960
    property int thumbSourceHeight: 540

    // --- Animation (Werte aus ricev2/Style.qml) -----------------------------
    property int animFast: 150
    property int animNormal: 200
    property int animEnter: 250
    property int animMedium: 300
    property int animExpand: 350
    property int anim300: 300
    property int anim400: 400

    // --- Farben -------------------------------------------------------------
    // Rollen wie in ricev2/Colors.qml benannt (primary/tertiary/
    // surfaceContainer/textColor), eigene Fallback-Werte statt matugen.
    property color overlayBackgroundColor: "#cc0b0b12"
    property color surfaceContainer: "#1a1a20"
    property color primary: "#7aa2ff"
    property color tertiary: "#9a9aa4"
    property color textColor: "#f2f2f5"
}
