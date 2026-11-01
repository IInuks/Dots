import QtQuick
import "."

// Renders one zone (left/center/right) as a row of module instances.
// Shared verbatim by CustomBarRoot.qml (the real, running bar) and the
// editor's live preview, so what you see while editing is exactly what the
// real bar will show.
Row {
    id: root

    property var items: []       // [{ type, settings }, ...]
    property color foreground: "#e8e8f0"
    property color accent: "#5b8cff"
    property string fontFamily: "monospace"
    property int fontSize: 13
    property int moduleSpacing: 12

    spacing: moduleSpacing

    // Local instance, not a singleton reference -- see ModuleRegistry.qml's
    // top comment for why.
    ModuleRegistry { id: registry }

    Repeater {
        model: root.items
        delegate: Loader {
            id: modLoader
            required property var modelData
            readonly property var _meta: registry.byType(modelData.type)
            source: _meta ? Qt.resolvedUrl(_meta.file) : ""
            anchors.verticalCenter: parent ? parent.verticalCenter : undefined

            onLoaded: {
                item.foreground = root.foreground;
                item.accent = root.accent;
                item.fontFamily = root.fontFamily;
                item.fontSize = root.fontSize;
                item.settings = modelData.settings || {};
            }
        }
    }
}
