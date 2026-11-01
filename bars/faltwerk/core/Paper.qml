pragma Singleton
import QtQuick
import Quickshell

// Faltwerk-Theme: jedes "Papier" ist eine komplette Palette. Der Name wird in
// Store.paperName gespeichert; gewechselt wird ueber den Faecher (PaperMenu),
// die Bar blaettert dabei einmal um (siehe bar/Bar.qml, flip).
//
// KEIN `Behavior` in dieser Datei -- crasht Quickshell 0.3.1 in Singletons.
Singleton {
    id: root

    readonly property var fixed: ({
        washi: {
            title: "Washi", note: "Reispapier, Zinnober", accentInk: "#ffffff",
            paper: "#f3ede1", deep: "#e3d8c4", ink: "#2b2622", soft: "#7a6f63",
            accent: "#d9472b", second: "#2f5d8a", grain: 0.10, dark: false,
            tiles: ["#d9472b", "#2f5d8a", "#e0a43a", "#3f8a6e", "#8e4a7a", "#c86b3c", "#4a6fa5", "#b5893a"]
        },
        kraft: {
            title: "Kraft", note: "Packpapier, Tinte", accentInk: "#f6eedd",
            paper: "#cfae84", deep: "#b8946a", ink: "#2c2117", soft: "#5e4732",
            accent: "#1f4e5f", second: "#8c2f1c", grain: 0.16, dark: false,
            tiles: ["#1f4e5f", "#8c2f1c", "#3d5a3a", "#2c2117", "#6b4a8a", "#a8552b", "#2f6f73", "#7a3b4f"]
        },
        tusche: {
            title: "Tusche", note: "Nachtpapier, Gold", accentInk: "#1c1a20",
            paper: "#24222a", deep: "#17161b", ink: "#ece5d6", soft: "#9a927f",
            accent: "#e3a83c", second: "#7fa7c9", grain: 0.20, dark: true,
            tiles: ["#e3a83c", "#7fa7c9", "#c96a5a", "#7fb08f", "#b48ac4", "#d9c48a", "#5f8fb8", "#c98a4a"]
        },
        blaupause: {
            title: "Blaupause", note: "Bauplan, Kreide", accentInk: "#1b2a48",
            paper: "#1f4374", deep: "#163156", ink: "#eaf1ff", soft: "#9cb6dc",
            accent: "#ffd35a", second: "#ff8a6a", grain: 0.14, dark: true,
            tiles: ["#ffd35a", "#ff8a6a", "#8fd3ff", "#b3e6a0", "#f2a8d8", "#ffffff", "#ffb347", "#9ad1c4"]
        },
        sakura: {
            title: "Sakura", note: "Kirschbluete, Moos", accentInk: "#ffffff",
            paper: "#f7e6e8", deep: "#ead0d4", ink: "#3a2a2e", soft: "#8a6c72",
            accent: "#c43d64", second: "#4f7a5a", grain: 0.08, dark: false,
            tiles: ["#c43d64", "#4f7a5a", "#e48aa5", "#7a5c8e", "#d9824a", "#5a7fa8", "#a8445a", "#8a9a4a"]
        }
    })
    // "adaptiv" kommt live aus dem Wallpaper (core/Wallpaper.qml)
    readonly property var palettes: Object.assign({}, fixed, { adaptiv: Wallpaper.palette })
    readonly property var order: ["adaptiv", "washi", "kraft", "tusche", "blaupause", "sakura"]

    readonly property string name: palettes[Store.paperName] ? Store.paperName : "washi"
    readonly property var p: palettes[name]

    readonly property color paper: p.paper
    readonly property color deep: p.deep
    readonly property color ink: p.ink
    readonly property color soft: p.soft
    readonly property color accent: p.accent
    readonly property color second: p.second
    readonly property color accentInk: p.accentInk
    readonly property real grain: p.grain
    readonly property bool dark: p.dark
    readonly property var tiles: p.tiles

    // Gewuenschtes Papier: die Bar sieht die Aenderung, blaettert um und
    // setzt in der Mitte der Animation Store.paperName (= commit()).
    property string pending: ""
    function request(n) {
        if (!palettes[n] || n === name)
            return;
        pending = "";
        pending = n;
    }
    function commit() {
        if (pending === "@adaptiv")
            Wallpaper.apply();
        else if (pending !== "" && pending !== name)
            Store.setPaper(pending);
    }
    // Wallpaper hat sich geaendert, waehrend "adaptiv" aktiv ist: Leiste
    // blaettert um, in der Mitte wird die neue Palette uebernommen.
    function refresh() {
        pending = "";
        pending = "@adaptiv";
    }

    function tileColor(key) {
        let h = 0;
        for (let i = 0; i < key.length; i++)
            h = (h * 31 + key.charCodeAt(i)) >>> 0;
        return tiles[h % tiles.length];
    }

    // Schrift: Serifen fuer "gedruckt", Nerd-Font nur fuer Glyphen
    readonly property string serif: "DejaVu Serif"
    readonly property string mono: "JetBrainsMono Nerd Font Propo"

    readonly property int tQuick: 180
    readonly property int tFold: 460
    readonly property int tSlow: 700

    readonly property int barHeight: 38
    readonly property int barMargin: 8
    readonly property int barZone: barHeight + barMargin + 4
}
