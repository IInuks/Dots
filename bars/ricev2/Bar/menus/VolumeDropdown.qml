import QtQuick
import Quickshell.Services.Pipewire
import "../../"

// Volume dropdown content (menus prompt 1.1): OUTPUT section (all sinks,
// default gets a filled speaker icon) then INPUT (all sources, default gets
// a filled mic icon), each row with its own slider underneath. Clicking a
// row's name makes that device the default (Pipewire.preferredDefaultAudioSink/
// Source); dragging a row's slider only ever touches that device's own volume.
Column {
    id: root
    width: Style.dropdownMinWidth - 24
    spacing: 8

    // PwNode has no `isSource` (checked against this Quickshell version's
    // qmltypes -- only `isSink` exists), so sources are picked out via the
    // AudioSource type flag instead.
    readonly property var _allNodes: Pipewire.nodes ? Pipewire.nodes.values : []
    readonly property var _sinks: root._allNodes.filter(n => n.isSink && !n.isStream)
    readonly property var _sources: root._allNodes.filter(n => !n.isStream && (n.type & PwNodeType.AudioSource) === PwNodeType.AudioSource)
    readonly property var _defaultSink: Pipewire.defaultAudioSink
    readonly property var _defaultSource: Pipewire.defaultAudioSource

    PwObjectTracker {
        objects: root._sinks.concat(root._sources)
    }

    function _label(node) {
        return node.description || node.nickname || node.name || "?";
    }

    Text {
        text: "OUTPUT"
        font.family: Style.textFont
        font.pixelSize: Style.fontSubtitle
        font.weight: Font.DemiBold
        color: Colors.primary
    }

    Repeater {
        model: root._sinks

        Column {
            id: sinkRow
            required property var modelData
            readonly property bool isDefault: root._defaultSink && sinkRow.modelData.id === root._defaultSink.id
            width: root.width
            spacing: 4

            MenuRow {
                width: parent.width
                iconGlyph: sinkRow.isDefault ? "\u{F057E}" : "\u{F0580}"
                label: root._label(sinkRow.modelData)
                value: sinkRow.modelData.audio ? Math.round(sinkRow.modelData.audio.volume * 100) + "%" : ""
                bold: sinkRow.isDefault

                MouseArea {
                    anchors.fill: parent
                    onClicked: Pipewire.preferredDefaultAudioSink = sinkRow.modelData
                }
            }
            VolumeSlider {
                width: parent.width
                value: sinkRow.modelData.audio ? sinkRow.modelData.audio.volume : 0
                onMoved: v => { if (sinkRow.modelData.audio) sinkRow.modelData.audio.volume = v; }
            }
        }
    }

    Text {
        topPadding: 8
        text: "INPUT"
        font.family: Style.textFont
        font.pixelSize: Style.fontSubtitle
        font.weight: Font.DemiBold
        color: Colors.primary
    }

    Repeater {
        model: root._sources

        Column {
            id: sourceRow
            required property var modelData
            readonly property bool isDefault: root._defaultSource && sourceRow.modelData.id === root._defaultSource.id
            width: root.width
            spacing: 4

            MenuRow {
                width: parent.width
                iconGlyph: sourceRow.isDefault ? "\u{F036C}" : "\u{F036D}"
                label: root._label(sourceRow.modelData)
                value: sourceRow.modelData.audio ? Math.round(sourceRow.modelData.audio.volume * 100) + "%" : ""
                bold: sourceRow.isDefault

                MouseArea {
                    anchors.fill: parent
                    onClicked: Pipewire.preferredDefaultAudioSource = sourceRow.modelData
                }
            }
            VolumeSlider {
                width: parent.width
                value: sourceRow.modelData.audio ? sourceRow.modelData.audio.volume : 0
                onMoved: v => { if (sourceRow.modelData.audio) sourceRow.modelData.audio.volume = v; }
            }
        }
    }
}
