import QtQuick
import Quickshell
import Quickshell.Io

// Mirrors bars/shellbar/Theme.qml exactly: same mono/monoInvert/adaptive
// presets, same custom-color math. Reads the exact same state file
// shellbar itself persists to (Quickshell.statePath("theme.json") from
// *inside* shellbar) -- computed here via Qt.md5() rather than hardcoded,
// since Quickshell derives that path as md5(<shellDir>/shell.qml)
// (confirmed empirically against a throwaway `qs` instance). Read-only,
// never writes, never imports shellbar's QML.
QtObject {
    id: root

    readonly property string _statePath: Quickshell.env("HOME") + "/.local/state/quickshell/by-shell/"
        + Qt.md5("~/quickdots/bars/shellbar/shell.qml") + "/theme.json"

    property FileView _state: FileView {
        path: root._statePath
        printErrors: false
        watchChanges: true
        adapter: JsonAdapter {
            property string presetKey: "mono"
            property bool useCustomColors: false
            property int customSurfaceR: 28
            property int customSurfaceG: 28
            property int customSurfaceB: 38
            property real customOpacity: 1.0
            property int customAccentR: 91
            property int customAccentG: 140
            property int customAccentB: 255
            property bool customForegroundLight: true
        }
        onFileChanged: reload()
    }

    property FileView _wal: FileView {
        path: Quickshell.env("HOME") + "/.cache/wal/colors.json"
        printErrors: false
        watchChanges: true
        property var parsed: null
        onLoaded: {
            try { parsed = JSON.parse(text()); } catch (e) { parsed = null; }
        }
        onFileChanged: reload()
    }

    readonly property color adaptiveSurface: _wal.parsed ? _wal.parsed.special.background : "#1c1c26"
    readonly property color adaptiveForeground: _wal.parsed ? _wal.parsed.special.foreground : "#e8e8f0"
    readonly property color adaptiveAccent: _wal.parsed ? _wal.parsed.colors.color4 : "#5b8cff"

    readonly property var presets: ({
        adaptive: { surface: adaptiveSurface, foreground: adaptiveForeground, accent: adaptiveAccent },
        mono: { surface: "#ffffff", foreground: "#111111", accent: "#111111" },
        monoInvert: { surface: "#000000", foreground: "#ffffff", accent: "#ffffff" }
    })

    readonly property var customPreset: ({
        surface: Qt.rgba(_state.adapter.customSurfaceR / 255, _state.adapter.customSurfaceG / 255, _state.adapter.customSurfaceB / 255, _state.adapter.customOpacity),
        foreground: _state.adapter.customForegroundLight ? "#f2f2f6" : "#101014",
        accent: Qt.rgba(_state.adapter.customAccentR / 255, _state.adapter.customAccentG / 255, _state.adapter.customAccentB / 255, 1)
    })

    readonly property var current: _state.adapter.useCustomColors
        ? root.customPreset
        : (root.presets[_state.adapter.presetKey] ?? root.presets.mono)

    readonly property var surface: current.surface
    readonly property var foreground: current.foreground
    readonly property var accent: current.accent
    readonly property real barOpacity: _state.adapter.useCustomColors ? _state.adapter.customOpacity : 1.0
}
