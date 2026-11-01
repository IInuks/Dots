pragma Singleton
import QtQuick
import Quickshell

// Geschenkpapier-Palette. Jedes Geschenk in der Leiste bekommt eine Rolle
// Papier (paper/stripe/pattern) und ein Band (ribbon). Ausgepackt liegt der
// Inhalt auf cremefarbenem Seidenpapier (tissue).
Singleton {
    readonly property var papers: [
        { paper: "#d9434f", stripe: "#ee7782", ribbon: "#ffd166", pattern: "stripes" },
        { paper: "#1f8a7e", stripe: "#3db3a4", ribbon: "#fbf3e4", pattern: "dots" },
        { paper: "#e6a532", stripe: "#f6cd6e", ribbon: "#c2364a", pattern: "zigzag" },
        { paper: "#6e4fb8", stripe: "#9579dc", ribbon: "#7fe0c4", pattern: "stars" },
        { paper: "#2f6fd0", stripe: "#5e95e8", ribbon: "#ffb3c6", pattern: "checks" },
        { paper: "#e86a9a", stripe: "#f6a0c0", ribbon: "#2f2a5a", pattern: "waves" },
        { paper: "#3f9a4e", stripe: "#6cc27a", ribbon: "#fbf3e4", pattern: "stripes" }
    ]

    function paper(i) {
        const n = papers.length;
        return papers[((i % n) + n) % n];
    }

    readonly property color tissue: "#fbf3e4"
    readonly property color tissueEdge: "#e9dcc4"
    readonly property color ink: "#2a2130"
    readonly property color inkSoft: "#86768a"
    readonly property color shadow: "#55000000"

    readonly property string font: "Quicksand"
    readonly property string icons: "Symbols Nerd Font"
    readonly property int textSize: 13

    // Nerd-Font-Glyphen (als Escapes, damit die Quelltexte reines ASCII bleiben)
    readonly property string iGift: "\uf06b"
    readonly property string iPower: "\uf011"
    readonly property string iVolHigh: "\uf028"
    readonly property string iVolLow: "\uf027"
    readonly property string iVolOff: "\uf026"
    readonly property string iBulb: "\uf0eb"
    readonly property string iFlag: "\uf024"
    readonly property string iHeart: "\uf004"
    readonly property string iQuestion: "\uf128"
    readonly property string iSearch: "\uf002"
    readonly property string iShuffle: "\uf074"
    readonly property string iLogout: "\uf08b"
    readonly property string iMoon: "\uf186"
    readonly property string iRestart: "\uf021"
    readonly property string iGrid: "\uf00a"
    readonly property string iStar: "\uf005"
}
