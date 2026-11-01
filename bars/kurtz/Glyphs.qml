pragma Singleton
import QtQuick
import Quickshell

// Filled/rounded Material Design glyphs from the installed Nerd Font
// (nf-md-*, same codepoints as MDI). Rendered with Theme.iconFont.
// Filled shapes only -- no thin outline icons (style guide section 7).
Singleton {
    readonly property string search: "\u{F0349}"
    readonly property string apps: "\u{F003B}"
    readonly property string rocket: "\u{F0463}"
    readonly property string sparkle: "\u{F0674}"
    readonly property string star4: "\u{F0AE2}"

    readonly property string volHigh: "\u{F057E}"
    readonly property string volMid: "\u{F0580}"
    readonly property string volLow: "\u{F057F}"
    readonly property string volMute: "\u{F075F}"

    readonly property string bell: "\u{F009A}"
    readonly property string bellOff: "\u{F009B}"
    readonly property string bellRing: "\u{F009E}"

    readonly property string cog: "\u{F0493}"
    readonly property string palette: "\u{F03D8}"
    readonly property string tune: "\u{F062E}"
    readonly property string power: "\u{F0425}"
    readonly property string lock: "\u{F033E}"
    readonly property string logout: "\u{F0343}"
    readonly property string restart: "\u{F0709}"
    readonly property string sleep: "\u{F04B2}"

    readonly property string wifi1: "\u{F091F}"
    readonly property string wifi2: "\u{F0922}"
    readonly property string wifi3: "\u{F0925}"
    readonly property string wifi4: "\u{F0928}"
    readonly property string wifiOff: "\u{F05AA}"
    readonly property string ethernet: "\u{F0200}"
    readonly property string bluetooth: "\u{F00AF}"

    readonly property string play: "\u{F040A}"
    readonly property string pause: "\u{F03E4}"
    readonly property string next: "\u{F04AD}"
    readonly property string prev: "\u{F04AE}"
    readonly property string music: "\u{F075A}"
    readonly property string mic: "\u{F036C}"
    readonly property string micOff: "\u{F036D}"

    readonly property string sun: "\u{F0599}"
    readonly property string moon: "\u{F0594}"
    readonly property string calendar: "\u{F00ED}"

    readonly property string cpu: "\u{F0EDF}"
    readonly property string memory: "\u{F035B}"
    readonly property string temp: "\u{F050F}"
    readonly property string monitor: "\u{F0379}"

    readonly property string close: "\u{F0156}"
    readonly property string check: "\u{F012C}"
    readonly property string trash: "\u{F0A79}"
    readonly property string left: "\u{F0141}"
    readonly property string right: "\u{F0142}"
    readonly property string refresh: "\u{F0450}"
    readonly property string animation: "\u{F05D8}"
    readonly property string message: "\u{F0369}"
    readonly property string flash: "\u{F0241}"
}
