import QtQuick
import QtQuick.Layouts
import ".."
import "../custombarlib" as Cbl

// Non-interactive miniature of the bar being edited -- same ZoneContent
// component the real running bar uses (CustomBarRoot.qml), so preview and
// reality never drift. enabled:false on the zone rows keeps clicking a
// preview module (e.g. workspaces) from touching the real system.
Item {
    id: root

    readonly property var adapter: CustomBarsStore.configFile.adapter
    readonly property var theme: adapter.theme || {}
    readonly property var zones: adapter.zones || {}
    readonly property bool adaptive: theme.mode === "adaptive"
    readonly property color surfaceColor: root.adaptive ? wal.surface : (theme.surface || "#1c1c26")
    readonly property color fgColor: root.adaptive ? wal.foreground : (theme.foreground || "#e8e8f0")
    readonly property color accentColor: root.adaptive ? wal.accent : (theme.accent || "#5b8cff")
    readonly property real opacityVal: theme.opacity !== undefined ? theme.opacity : 0.9
    readonly property real radiusVal: theme.radius !== undefined ? theme.radius : 14

    // Not a singleton -- see ModuleRegistry.qml's top comment (plain type
    // instantiation works fine across the custombarlib symlink, only
    // singleton property access breaks).
    Cbl.WalTheme { id: wal }

    function setIslandOffset(zone, dx) {
        const islands = Object.assign({}, root.adapter.islands);
        islands[zone] = Object.assign({}, islands[zone], { dx: dx });
        root.adapter.islands = islands;
    }

    width: parent ? parent.width : 380
    implicitHeight: adapter.style === "islands" ? 50 : 40

    // Style "bar": one continuous strip.
    Rectangle {
        visible: root.adapter.style !== "islands"
        anchors.fill: parent
        radius: root.radiusVal
        color: Qt.rgba(root.surfaceColor.r, root.surfaceColor.g, root.surfaceColor.b, root.opacityVal)

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 10
            anchors.rightMargin: 10
            spacing: 10
            enabled: false

            Cbl.ZoneContent {
                items: root.zones.left || []
                foreground: root.fgColor
                accent: root.accentColor
                fontSize: 11
                Layout.alignment: Qt.AlignVCenter
            }
            Item {
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignVCenter
                implicitHeight: centerZone.implicitHeight
                Cbl.ZoneContent {
                    id: centerZone
                    anchors.centerIn: parent
                    items: root.zones.center || []
                    foreground: root.fgColor
                    accent: root.accentColor
                    fontSize: 11
                }
            }
            Cbl.ZoneContent {
                items: root.zones.right || []
                foreground: root.fgColor
                accent: root.accentColor
                fontSize: 11
                Layout.alignment: Qt.AlignVCenter
            }
        }
    }

    // Style "islands": three separate floating chips, each independently
    // shaped/sized (adapter.islands[zone]) and horizontally draggable --
    // this is the one live editing surface for an island's position, the
    // real bar (CustomBarRoot.qml) only ever reads dx back out of the
    // config, it never writes to it itself. Only X is draggable -- all
    // three islands always share the same vertical level (see
    // CustomBarRoot.qml's fixed margins.top/bottom), so there's no dy to
    // edit. Dragging assigns x imperatively (via drag.target), which breaks
    // the declarative x binding below for that delegate instance --
    // _syncFromConfig() restores it once the drag ends and the offset has
    // been persisted, so a later external config reload (e.g. undo) still
    // repositions the chip correctly. "angle" only rotates the visible
    // Rectangle, same as CustomBarRoot.qml -- unlike the real bar's
    // PanelWindow, a plain Item here doesn't need bounding-box sizing to
    // avoid clipping, rotation is purely a paint transform.
    Item {
        id: islandsCanvas
        visible: root.adapter.style === "islands"
        anchors.fill: parent

        Repeater {
            model: ["left", "center", "right"]
            delegate: Rectangle {
                id: island
                required property string modelData
                readonly property var cfg: (root.adapter.islands && root.adapter.islands[modelData]) || {}
                readonly property string shape: cfg.shape || "rounded"
                readonly property real islandHeight: cfg.height || 34
                readonly property real pad: cfg.padding !== undefined ? cfg.padding : 10
                readonly property real explicitWidth: cfg.width || 0
                readonly property real angle: cfg.angle || 0
                readonly property real dx: cfg.dx || 0
                readonly property real baseX: modelData === "left" ? 0 : modelData === "right" ? (islandsCanvas.width - width) : (islandsCanvas.width - width) / 2

                function syncFromConfig() {
                    if (dragArea.drag.active) return;
                    x = Math.max(0, Math.min(islandsCanvas.width - width, baseX + dx));
                }

                width: Math.max(content.implicitWidth + pad * 2, explicitWidth)
                height: islandHeight
                rotation: angle
                y: (islandsCanvas.height - height) / 2
                radius: shape === "pill" ? height / 2 : shape === "square" ? 4 : Math.min(root.radiusVal, 14)
                color: Qt.rgba(root.surfaceColor.r, root.surfaceColor.g, root.surfaceColor.b, root.opacityVal)
                border.width: 1
                border.color: Qt.rgba(1, 1, 1, 0.15)

                Component.onCompleted: syncFromConfig()
                onDxChanged: syncFromConfig()
                onWidthChanged: syncFromConfig()

                Cbl.ZoneContent {
                    id: content
                    anchors.centerIn: parent
                    items: root.zones[island.modelData] || []
                    foreground: root.fgColor
                    accent: root.accentColor
                    fontSize: 11
                    enabled: false
                }

                MouseArea {
                    id: dragArea
                    anchors.fill: parent
                    cursorShape: Qt.SizeHorCursor
                    drag.target: island
                    drag.axis: Drag.XAxis
                    drag.minimumX: 0
                    drag.maximumX: Math.max(0, islandsCanvas.width - island.width)
                    onReleased: root.setIslandOffset(island.modelData, Math.round(island.x - island.baseX))
                }
            }
        }
    }
}
