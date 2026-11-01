import QtQuick
import "../.."

// Shared popup shell for module menus (power confirm, sound mixer, and
// whatever Etappe 8 adds). Reparents onto a full-window overlay layer
// instead of staying inside the bar's own row -- Bar.qml's PanelWindow
// only reserves Theme.barHeight via exclusiveZone but is actually taller
// (see Bar.qml's popupLayer comment), so this can grow downward below the
// strip without being clipped by it. Same technique bars/shellbar's
// LiquidMenu.qml uses for its dropdowns.
Item {
    id: root

    required property Item overlay
    required property Item anchorItem
    property bool open: false
    property real popupWidth: 220
    property real popupHeight: 160
    default property alias content: contentArea.data

    // Escape-to-close, generic for every menu that doesn't already manage
    // its own focused input (LauncherMenu's search field handles Escape
    // itself and grabs focus on its own -- see its onActiveChanged -- so
    // this never fires there; its own forceActiveFocus() call runs after
    // this one for the same `open` change, since it lives on a child
    // instantiated after this Item's own properties, and simply wins).
    // Requires Bar.qml's WlrLayershell.keyboardFocus to actually route key
    // events to this window while a popup is open -- with
    // WlrKeyboardFocus.None (the default when nothing is open) the
    // compositor never delivers key events here at all, no matter what
    // holds `focus` in the scene.
    signal closeRequested
    Keys.onEscapePressed: root.closeRequested()
    onOpenChanged: if (root.open)
        root.forceActiveFocus()

    parent: root.overlay
    z: 1000

    // Item.mapToItem() computes a one-off snapshot -- it does not re-run
    // when anchorItem's geometry changes later, because that read happens
    // inside a C++-invokable call rather than a plain QML property
    // expression the binding evaluator can register as a dependency (see
    // feedback_qml_maptoitem_non_reactive.md). A first fix tried forcing a
    // re-run via a synthetic "sum of anchorItem's own x/y/width/height"
    // dependency, but that's blind to anything above anchorItem in the
    // tree: for network/bluetooth/volume -- all siblings inside Bar.qml's
    // right-anchored status Row -- their *absolute* screen x depends on
    // their own width plus the combined width of every sibling *after*
    // them (that's what anchoring a Row to the right edge means: earlier
    // siblings never move a later one, but the Row's own x shifts whenever
    // its total width changes). Tray icons appearing, Battery's visibility
    // flipping, Media's title showing up -- any later sibling resizing
    // moves the Row itself without changing volumeModule's own local x at
    // all, so the old dependency term never fired and the popup froze at
    // its very first (often pre-layout) position -- confirmed by injecting
    // a live debug readout that showed the cached anchor over 100px off
    // from a fresh direct measurement. clockModule (anchors.centerIn, no
    // Row) and powerButton (last in the Row, nothing after it to shift it)
    // never had a sibling able to move them, which is why only network/
    // bluetooth/volume/battery were affected.
    //
    // Fix: walk each item's own ancestor chain up to its window root,
    // summing plain `.x`/`.y` at every step instead of calling
    // mapToItem(). Every read here is a real notifying QML property, so
    // *any* ancestor moving anywhere in either chain -- including the
    // Row's own anchored x -- correctly invalidates this binding.
    function _absoluteOffset(item) {
        let x = 0, y = 0, cur = item;
        while (cur) {
            x += cur.x;
            y += cur.y;
            cur = cur.parent;
        }
        return Qt.point(x, y);
    }
    readonly property point _anchor: {
        if (!root.anchorItem || !root.overlay)
            return Qt.point(0, 0);
        const a = root._absoluteOffset(root.anchorItem);
        const o = root._absoluteOffset(root.overlay);
        return Qt.point(a.x - o.x + root.anchorItem.width / 2, a.y - o.y + root.anchorItem.height);
    }

    x: Math.max(Theme.gap, Math.min(_anchor.x - popupWidth / 2, (root.overlay ? root.overlay.width : popupWidth) - popupWidth - Theme.gap))
    y: _anchor.y + Theme.gap

    width: popupWidth
    height: root.open ? popupHeight : 0
    clip: true
    visible: height > 0.5

    Behavior on height {
        NumberAnimation {
            duration: Theme.durSlow
            easing.type: Theme.easeOutBack
        }
    }

    LcdSurface {
        anchors.fill: parent
    }
    BevelPanel {
        anchors.fill: parent
    }

    Item {
        id: contentArea
        anchors.fill: parent
        anchors.margins: Theme.gap
        opacity: root.open ? 1 : 0
        Behavior on opacity {
            SequentialAnimation {
                PauseAnimation {
                    duration: root.open ? Theme.durBase : 0
                }
                NumberAnimation {
                    duration: Theme.durBase
                    easing.type: Theme.easeOut
                }
            }
        }
    }
}
