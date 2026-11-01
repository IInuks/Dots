pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Colors track the user's pywal cache (~/.cache/wal/colors.json) live, so the
// bar always follows whatever wallpaper/theme is currently applied -- no
// manual theme switch needed. Falls back to a fixed soft palette when pywal
// hasn't run yet or the file is missing.
QtObject {
    id: root

    readonly property var _fallback: ({
        background: "#1c1d24",
        foreground: "#e7e7ee",
        muted: "#8d8fa0",
        accent: "#9aa5ff"
    })

    property var _wal: null

    property color background: _wal ? _wal.background : _fallback.background
    property color foreground: _wal ? _wal.foreground : _fallback.foreground
    property color muted: _wal ? _wal.muted : _fallback.muted
    property color accent: _wal ? _wal.accent : _fallback.accent

    property bool _settle: false
    Component.onCompleted: Qt.callLater(() => root._settle = true)
    Behavior on background { enabled: root._settle; ColorAnimation { duration: root.animSoft } }
    Behavior on foreground { enabled: root._settle; ColorAnimation { duration: root.animSoft } }
    Behavior on muted { enabled: root._settle; ColorAnimation { duration: root.animSoft } }
    Behavior on accent { enabled: root._settle; ColorAnimation { duration: root.animSoft } }

    property FileView _walFile: FileView {
        path: Quickshell.env("HOME") + "/.cache/wal/colors.json"
        watchChanges: true
        printErrors: false
        onLoaded: root._applyWal(text())
        onFileChanged: reload()
    }

    function _applyWal(raw) {
        let data;
        try { data = JSON.parse(raw); } catch (e) { return; }
        const special = data.special || {};
        const colors = data.colors || {};
        if (!special.background || !special.foreground) return;
        root._wal = {
            background: special.background,
            foreground: special.foreground,
            muted: colors.color8 || Qt.alpha(special.foreground, 0.6),
            accent: colors.color4 || colors.color6 || special.foreground
        };
    }

    // -- transparency (toggled from the settings popup, persisted) --
    readonly property real paneOpacity: Settings.transparencyEnabled ? 0.58 : 0.98
    readonly property color paneColor: Qt.rgba(background.r, background.g, background.b, paneOpacity)
    readonly property color hairline: Qt.alpha(foreground, 0.08)
    readonly property color hover: Qt.alpha(foreground, 0.10)
    readonly property color activeFill: Qt.alpha(accent, 0.85)

    // -- geometry: soft pill segments, generous radius, no hard borders --
    readonly property int paneHeight: 34
    readonly property int pillRadius: paneHeight / 2
    readonly property int marginTop: 10
    readonly property int marginSide: 16
    readonly property int groupSpacing: 8
    readonly property int paddingH: 14
    readonly property int itemSpacing: 10
    readonly property int popupGap: 10
    readonly property int popupRadius: 22
    readonly property int topReserve: marginTop + paneHeight

    readonly property real shadowOpacity: 0.32
    readonly property real shadowBlur: 0.55

    // -- fonts (no nerd font installed here -- plain glyphs + system sans) --
    readonly property string fontFamily: "sans-serif"
    readonly property int fontSizeSmall: 11
    readonly property int fontSizeNormal: 12
    readonly property int fontSizeLarge: 15
    readonly property int fontSizeClock: 32

    // -- motion --
    readonly property int animFast: 130
    readonly property int animSoft: 260
}
