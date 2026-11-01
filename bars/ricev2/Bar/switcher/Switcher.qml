import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import "../../"

// Menus-prompt section 3: the Alt-Tab window switcher overlay, slice
// mode only (the optional wheel/grid modes are deferred, same "ship the
// default, defer the optional extra" call the launcher's hex/grid modes
// and roundCorners already made -- see README "Noch nicht gebaut").
//
// Window data comes from mango's own IPC, not the spec's placeholder
// [niri msg -j windows / hyprctl clients -j]: `mmsg get all-clients`
// returns the same {id, title, appid, tags, is_focused, is_floating,
// is_scratchpad, ...} shape bars/quickbar/MangoState.qml already
// consumes from `mmsg watch all-clients` on this system, and
// `mmsg dispatch focusid client,<id>` / `mmsg dispatch killclient
// client,<id>` (confirmed against mango's own source --
// src/dispatch/bind_define.h's focusid()/killclient() both honor
// arg->tc, which src/ipc/ipc.h populates from a "client,<id>" token) are
// exactly the mmsg equivalents of niri's focus-window/close-window
// switcher actions. bars/quickbar/MangoState.qml's focusClient() already
// uses the identical "focusid","client,"+id call on this same system.
Item {
    id: root

    IpcHandler {
        target: "switch"
        function open(): void { root._open(); }
        function next(): void { SwitcherState.moveBy(1); }
        function prev(): void { SwitcherState.moveBy(-1); }
        function confirm(): void { root._confirm(); }
        function cancel(): void { SwitcherState.open = false; }
        function close(): void { root._closeSelected(); }
    }

    // Scratchpad clients are deliberately excluded -- they're hidden by
    // design (same "ausgeblendet ohne Daten" judgment call this repo
    // already makes for absent hardware widgets), so cluttering Alt-Tab
    // with them would fight their own point. Everything else (including
    // minimized windows) stays: mango's own focusid() un-minimizes a
    // minimized target itself (client_active() in mango.c), so selecting
    // one here just works.
    function _reorder(clients) {
        const filtered = (clients || []).filter(c => !c.is_scratchpad && !c.is_namedscratchpad);
        const idx = filtered.findIndex(c => c.is_focused);
        if (idx <= 0)
            return filtered;
        return filtered.slice(idx).concat(filtered.slice(0, idx));
    }

    function _onFetched(text) {
        let data = null;
        try {
            data = JSON.parse(text);
        } catch (e) {
            data = null;
        }
        const list = root._reorder(data ? data.clients : []);
        SwitcherState.windows = list;
        // Spec: "open öffnet und springt direkt zum zweiten Fenster" --
        // the focused client was rotated to index 0 above, so index 1 is
        // exactly "the next window over".
        SwitcherState.selectedIndex = list.length > 1 ? 1 : 0;
        SwitcherState.open = true;
    }

    function _open() {
        // Compositor-side Alt+Tab always calls this same "open" target on
        // every keydown -- mango's bind system has no notion of "held
        // modifier, repeated tap" vs. "fresh press", so the classic hold-
        // Alt-tap-Tab-repeatedly cycling has to be reconstructed here: if
        // the overlay is already open, treat the repeat tap as "next"
        // instead of re-fetching and resetting the selection back to
        // index 1 every time (spec section 6 pairs Alt+Tab only with
        // "open", not "next" -- this is what makes that pairing actually
        // behave like Alt-Tab in practice).
        if (SwitcherState.open) {
            SwitcherState.moveBy(1);
            return;
        }
        // Toggle running to force a fresh one-shot run even if a
        // previous fetch is somehow still in flight (same restart idiom
        // MangoIpc.qml's watch-process timers use).
        fetchProc.running = false;
        fetchProc.running = true;
    }

    function _confirm() {
        const w = SwitcherState.windows[SwitcherState.selectedIndex];
        if (w)
            Quickshell.execDetached(["mmsg", "dispatch", "focusid", "client," + w.id]);
        SwitcherState.open = false;
    }

    // Closes the selected window and drops it from the local snapshot
    // optimistically -- no re-fetch, since mango's killclient() is a
    // graceful pending-close (pending_kill_client in mango.c), not an
    // instant removal, so there's nothing new to read back immediately
    // anyway. Leaves the switcher open on "NO WINDOWS" if that was the
    // last entry, per spec's own empty-state text for that case.
    function _closeSelected() {
        const w = SwitcherState.windows[SwitcherState.selectedIndex];
        if (!w)
            return;
        Quickshell.execDetached(["mmsg", "dispatch", "killclient", "client," + w.id]);
        SwitcherState.removeSelected();
    }

    property Process _fetchProc: Process {
        id: fetchProc
        command: ["mmsg", "get", "all-clients"]
        stdout: StdioCollector {
            onStreamFinished: root._onFetched(text)
        }
    }

    PanelWindow {
        id: win

        screen: {
            const named = Quickshell.screens.find(s => s.name === Config.monitorName);
            return named ? named : Quickshell.screens[0];
        }

        WlrLayershell.namespace: "window-switcher-parallel"
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: SwitcherState.open ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

        anchors.top: true
        anchors.bottom: true
        anchors.left: true
        anchors.right: true
        color: "transparent"
        exclusiveZone: 0

        visible: SwitcherState.open

        Rectangle {
            id: dimmer
            anchors.fill: parent
            color: "black"
            opacity: SwitcherState.open ? 0.5 : 0
            Behavior on opacity { NumberAnimation { duration: Style.anim300 } }
        }

        MouseArea {
            anchors.fill: parent
            onClicked: SwitcherState.open = false
        }

        // Card: fixed 1600 width (spec), unlike the launcher's card which
        // just equals its own unclamped list width -- clipped here so a
        // longer window list scrolls past the edges instead of the card
        // growing past 1600.
        Item {
            id: card
            anchors.centerIn: parent
            width: Style.switcherCardWidth
            height: Style.sliceHeight + Style.switcherCardHeightPad
            clip: true
            opacity: 0

            states: State {
                name: "shown"
                when: SwitcherState.open
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

            MouseArea {
                anchors.fill: parent
            }

            ListView {
                id: listView
                anchors.centerIn: parent
                height: Style.sliceHeight
                width: Style.sliceExpandedWidth + (Style.sliceVisibleCount - 1) * (Style.sliceWidth + Style.sliceSpacing)

                orientation: ListView.Horizontal
                interactive: false
                spacing: Style.sliceSpacing
                model: SwitcherState.windows

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

                // `index`/`modelData` not redeclared -- SwitchDelegate.qml
                // already declares them as required properties, and
                // Quickshell auto-injects the ListView's own index/
                // modelData into a matching-named required property
                // (memory: feedback_qml_child_property_shadows_outer_id).
                delegate: SwitchDelegate {
                    selectedIndex: SwitcherState.selectedIndex
                    onSelectRequested: SwitcherState.selectedIndex = index
                    onActivated: root._confirm()
                }
            }

            Text {
                anchors.centerIn: parent
                visible: SwitcherState.windows.length === 0
                text: "NO WINDOWS"
                font.family: Style.textFont
                font.pixelSize: 18
                font.bold: true
                font.letterSpacing: 2
                color: Colors.outline
            }
        }

        Connections {
            target: SwitcherState
            function onSelectedIndexChanged() {
                listView.positionViewAtIndex(SwitcherState.selectedIndex, ListView.Center);
            }
        }
        Component.onCompleted: listView.positionViewAtIndex(SwitcherState.selectedIndex, ListView.Center)

        // Keyboard only -- spec's "Steuerung" bullet for the switcher
        // lists no mouse behavior (unlike the launcher's explicit mouse-
        // move-select/wheel-scroll rules in section 2), so none is added
        // here beyond SwitchDelegate's own plain click-to-select/confirm.
        // `close` has no key of its own either: like every other cross-
        // component action in this repo, the physical key (spec section
        // 6: Alt+C) lives in the compositor bind calling the IPC target,
        // not in this Keys handler.
        Item {
            anchors.fill: parent
            focus: SwitcherState.open
            Keys.onLeftPressed: SwitcherState.moveBy(-1)
            Keys.onRightPressed: SwitcherState.moveBy(1)
            Keys.onReturnPressed: root._confirm()
            Keys.onEnterPressed: root._confirm()
            Keys.onEscapePressed: SwitcherState.open = false
        }
    }
}
