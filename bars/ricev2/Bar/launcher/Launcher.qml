import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import "../../"

// Menus-prompt section 2: the app-launcher overlay. Three display modes
// (Config.launcherDisplayMode): "slice" (spec default, skewed overlapping
// strips), "hex" (honeycomb, HexDelegate.qml) and "grid" (plain tiles,
// GridDelegate.qml) -- see README "Noch nicht gebaut" for when hex/grid
// were added. Single-monitor only (Config.monitorName / Quickshell.screens[0]
// fallback, same pattern BarShell.qml/PopupHost.qml use) -- unlike the power
// menu, the spec never asks for a dimmer across every screen here.
Item {
    id: root

    IpcHandler {
        target: "launcher"
        function toggle(): void { LauncherState.toggle(); }
    }

    readonly property var appModel: AppIndex.filtered(LauncherState.filter, LauncherState.searchText)
    onAppModelChanged: LauncherState.moveBy(0, root.appModel.length)

    readonly property string _mode: Config.launcherDisplayMode

    // Wheel/Up/Down step: 1 slice at a time in "slice" mode (unchanged
    // behavior), one full row (= column count) in "hex"/"grid" mode, since
    // those lay out in rows rather than a single scrolling strip.
    readonly property int _rowStep: root._mode === "grid" ? Style.gridCols : (root._mode === "hex" ? Style.hexCols : 1)

    function _next() { LauncherState.moveBy(1, root.appModel.length); }
    function _prev() { LauncherState.moveBy(-1, root.appModel.length); }
    function _down() { LauncherState.moveBy(root._rowStep, root.appModel.length); }
    function _up() { LauncherState.moveBy(-root._rowStep, root.appModel.length); }
    function _activate() {
        const app = root.appModel[LauncherState.selectedIndex];
        if (app) {
            AppIndex.launch(app);
            LauncherState.hide();
        }
    }

    // -- Per-mode content size, used both for the delegate layouts below
    // and to size the card/dimmer-window around whichever mode is active.
    readonly property real _sliceContentWidth: Style.sliceExpandedWidth + (Style.sliceVisibleCount - 1) * (Style.sliceWidth + Style.sliceSpacing)
    readonly property real _sliceContentHeight: Style.sliceHeight

    readonly property real _gridContentWidth: Style.gridCols * Style.gridTileWidth + (Style.gridCols - 1) * Style.gridSpacing
    readonly property real _gridContentHeight: Style.gridRowsVisible * Style.gridTileHeight + (Style.gridRowsVisible - 1) * Style.gridSpacing

    readonly property real _hexContentWidth: Style.hexWidth + (Style.hexCols - 1) * Style.hexStepX
    readonly property real _hexContentHeight: Style.hexRows * (Style.hexHeight + Style.hexSpacing) - Style.hexSpacing + Style.hexArcAmplitude
    // Full height of every row the current filtered app list needs (hex
    // mode scrolls vertically past the default 3-row viewport, same idea
    // as GridView scrolling past gridRowsVisible).
    readonly property real _hexFullHeight: {
        const rows = Math.ceil(root.appModel.length / Style.hexCols);
        return rows > 0 ? rows * (Style.hexHeight + Style.hexSpacing) - Style.hexSpacing + Style.hexArcAmplitude : root._hexContentHeight;
    }

    readonly property real _contentWidth: root._mode === "grid" ? root._gridContentWidth : (root._mode === "hex" ? root._hexContentWidth : root._sliceContentWidth)
    readonly property real _contentHeight: root._mode === "grid" ? root._gridContentHeight : (root._mode === "hex" ? root._hexContentHeight : root._sliceContentHeight)

    PanelWindow {
        id: win

        screen: {
            const named = Quickshell.screens.find(s => s.name === Config.monitorName);
            return named ? named : Quickshell.screens[0];
        }

        WlrLayershell.namespace: "app-launcher-parallel"
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: LauncherState.open ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

        anchors.top: true
        anchors.bottom: true
        anchors.left: true
        anchors.right: true
        color: "transparent"
        exclusiveZone: 0

        visible: LauncherState.open

        Rectangle {
            id: dimmer
            anchors.fill: parent
            color: "black"
            opacity: LauncherState.open ? 0.5 : 0
            Behavior on opacity { NumberAnimation { duration: Style.anim300 } }
        }

        MouseArea {
            anchors.fill: parent
            onClicked: LauncherState.hide()
        }

        Item {
            id: card
            anchors.centerIn: parent
            width: root._contentWidth
            height: 65 + root._contentHeight + 20
            opacity: 0

            states: State {
                name: "shown"
                when: LauncherState.open
                PropertyChanges { card.opacity: 1 }
            }
            transitions: [
                Transition {
                    from: ""; to: "shown"
                    NumberAnimation { target: card; property: "opacity"; duration: Style.anim400; easing.type: Easing.OutCubic }
                },
                Transition {
                    from: "shown"; to: ""
                    NumberAnimation { target: card; property: "opacity"; duration: Style.animFast }
                }
            ]

            // Swallow clicks so they don't fall through to the dimmer's
            // close-on-click MouseArea above.
            MouseArea {
                anchors.fill: parent
            }

            FilterBar {
                id: filterBar
                y: 10
                anchors.horizontalCenter: parent.horizontalCenter
            }

            ListView {
                id: listView
                visible: root._mode === "slice"
                y: 65
                height: Style.sliceHeight
                width: root._sliceContentWidth
                anchors.horizontalCenter: parent.horizontalCenter

                orientation: ListView.Horizontal
                interactive: false
                spacing: Style.sliceSpacing
                model: root._mode === "slice" ? root.appModel : []

                readonly property int _spacerWidth: Math.max(0, (listView.width - Style.sliceExpandedWidth) / 2)
                header: Item { width: listView._spacerWidth; height: 1 }
                footer: Item { width: listView._spacerWidth; height: 1 }

                add: Transition {
                    ParallelAnimation {
                        NumberAnimation { property: "opacity"; from: 0; to: 1; duration: Style.animEnter }
                        NumberAnimation { property: "scale"; from: 0.85; to: 1; duration: Style.animEnter }
                    }
                }
                remove: Transition {
                    NumberAnimation { property: "opacity"; to: 0; duration: Style.animNormal; easing.type: Easing.InCubic }
                }
                move: Transition {
                    NumberAnimation { properties: "x,y"; duration: Style.animMedium }
                }
                displaced: Transition {
                    NumberAnimation { properties: "x,y"; duration: Style.animMedium }
                }

                // `index`/`modelData` are NOT redeclared here -- SliceDelegate.qml
                // already declares them as required properties, and Quickshell
                // auto-injects the Repeater/ListView context values into a
                // delegate's own required properties of matching name.
                // Redeclaring them on this instance would shadow that injection
                // with a self-referential, never-initialized property (memory:
                // feedback_qml_child_property_shadows_outer_id -- same trap
                // Bar/power/PowerMenu.qml's Repeater comment already documents).
                delegate: SliceDelegate {
                    selectedIndex: LauncherState.selectedIndex
                    onSelectRequested: LauncherState.selectedIndex = index
                    onActivated: root._activate()
                }
            }

            GridView {
                id: gridView
                visible: root._mode === "grid"
                y: 65
                width: root._gridContentWidth
                height: root._gridContentHeight
                anchors.horizontalCenter: parent.horizontalCenter

                interactive: false
                clip: true
                cellWidth: Style.gridTileWidth + Style.gridSpacing
                cellHeight: Style.gridTileHeight + Style.gridSpacing
                model: root._mode === "grid" ? root.appModel : []

                add: Transition {
                    ParallelAnimation {
                        NumberAnimation { property: "opacity"; from: 0; to: 1; duration: Style.animEnter }
                        NumberAnimation { property: "scale"; from: 0.85; to: 1; duration: Style.animEnter }
                    }
                }
                remove: Transition {
                    NumberAnimation { property: "opacity"; to: 0; duration: Style.animNormal; easing.type: Easing.InCubic }
                }
                move: Transition {
                    NumberAnimation { properties: "x,y"; duration: Style.animMedium }
                }
                displaced: Transition {
                    NumberAnimation { properties: "x,y"; duration: Style.animMedium }
                }

                delegate: GridDelegate {
                    selectedIndex: LauncherState.selectedIndex
                    onSelectRequested: LauncherState.selectedIndex = index
                    onActivated: root._activate()
                }
            }

            Flickable {
                id: hexFlick
                visible: root._mode === "hex"
                y: 65
                width: root._hexContentWidth
                height: root._hexContentHeight
                anchors.horizontalCenter: parent.horizontalCenter

                clip: true
                interactive: false
                boundsBehavior: Flickable.StopAtBounds
                contentWidth: width
                contentHeight: Math.max(height, root._hexFullHeight)
                Behavior on contentY { NumberAnimation { duration: Style.animMedium } }

                Repeater {
                    model: root._mode === "hex" ? root.appModel : []
                    delegate: HexDelegate {
                        selectedIndex: LauncherState.selectedIndex
                        onSelectRequested: LauncherState.selectedIndex = index
                        onActivated: root._activate()
                    }
                }
            }

            Text {
                anchors.centerIn: parent
                visible: root.appModel.length === 0
                text: "NO APPS"
                font.family: Style.textFont
                font.pixelSize: 18
                font.bold: true
                font.letterSpacing: 2
                color: Colors.outline
            }

            WheelHandler {
                onWheel: event => {
                    const down = event.angleDelta.y < 0 || event.angleDelta.x > 0;
                    if (root._mode === "slice") {
                        if (down) root._next(); else root._prev();
                    } else {
                        if (down) root._down(); else root._up();
                    }
                }
            }
        }

        function _hexScrollToSelected() {
            const idx = LauncherState.selectedIndex;
            const col = idx % Style.hexCols;
            const row = Math.floor(idx / Style.hexCols);
            const itemY = row * (Style.hexHeight + Style.hexSpacing) + Style.hexArcOffset(col);
            const itemCenterY = itemY + Style.hexHeight / 2;
            const maxY = Math.max(0, hexFlick.contentHeight - hexFlick.height);
            hexFlick.contentY = Math.max(0, Math.min(itemCenterY - hexFlick.height / 2, maxY));
        }

        Connections {
            target: LauncherState
            function onSelectedIndexChanged() {
                if (root._mode === "slice")
                    listView.positionViewAtIndex(LauncherState.selectedIndex, ListView.Center);
                else if (root._mode === "grid")
                    gridView.positionViewAtIndex(LauncherState.selectedIndex, GridView.Contain);
                else
                    win._hexScrollToSelected();
            }
        }
        Component.onCompleted: {
            listView.positionViewAtIndex(LauncherState.selectedIndex, ListView.Center);
        }

        Item {
            anchors.fill: parent
            focus: LauncherState.open
            Keys.onLeftPressed: root._prev()
            Keys.onRightPressed: root._next()
            Keys.onUpPressed: if (root._mode !== "slice") root._up()
            Keys.onDownPressed: if (root._mode !== "slice") root._down()
            Keys.onReturnPressed: root._activate()
            Keys.onEnterPressed: root._activate()
            Keys.onEscapePressed: LauncherState.hide()
            Keys.onPressed: event => {
                if (event.key === Qt.Key_Backspace) {
                    LauncherState.backspace();
                    event.accepted = true;
                } else if (event.text.length > 0 && event.text >= " ") {
                    LauncherState.typeText(event.text);
                    event.accepted = true;
                }
            }
        }
    }
}
