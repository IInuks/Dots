import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import "../../"

// Menus-prompt section 4: the power menu overlay. Spec puts a PanelWindow
// on EVERY monitor (Variants) so the dimmer covers the whole desktop and a
// click on any screen closes it, but the actual card -- and keyboard
// focus -- only lives on the configured main monitor (same
// Config.monitorName / Quickshell.screens[0]-fallback pattern BarShell.qml
// and PopupHost.qml already use).
Item {
    id: root

    // qs -p <dir> ipc call power toggle (spec section 6).
    IpcHandler {
        target: "power"
        function toggle(): void { PowerMenuState.toggle(); }
    }

    readonly property var _enabledOptions: Config.powerOptions.filter(o => o.enabled)

    function _runSelected() {
        const opts = root._enabledOptions;
        const opt = opts[PowerMenuState.selectedIndex];
        if (opt)
            Quickshell.execDetached(opt.command);
        PowerMenuState.hide();
    }

    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: win

            required property var modelData
            screen: modelData

            readonly property bool isMain: {
                const named = Quickshell.screens.find(s => s.name === Config.monitorName);
                return named ? modelData === named : modelData === Quickshell.screens[0];
            }

            WlrLayershell.namespace: "powermenu"
            WlrLayershell.layer: WlrLayer.Top
            // Only the main-monitor instance grabs keyboard focus -- one
            // Exclusive surface per open overlay, same reasoning as
            // BarShell.qml's single WLAN-password focus grab (memory:
            // feedback_wlr_layershell_keyboard_focus_none: None blocks ALL
            // key events forever, so the other screens' windows must stay
            // None rather than fight the main one for focus).
            WlrLayershell.keyboardFocus: (PowerMenuState.open && win.isMain) ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

            anchors.top: true
            anchors.bottom: true
            anchors.left: true
            anchors.right: true
            color: "transparent"
            exclusiveZone: 0

            visible: PowerMenuState.open

            // Dimmer, spec 0.45, fades 0<->1 in 300ms.
            Rectangle {
                id: dimmer
                anchors.fill: parent
                color: "black"
                opacity: PowerMenuState.open ? 0.45 : 0
                Behavior on opacity {
                    NumberAnimation { duration: Style.anim300 }
                }
            }

            // Spec's "fast unsichtbare Fläche, die Klicks abfängt" --
            // functionally the same click-catcher as the dimmer above (a
            // second, near-transparent Rectangle would add nothing beyond
            // what dimmer's own MouseArea already intercepts), so one
            // MouseArea over the full window covers both.
            MouseArea {
                anchors.fill: parent
                onClicked: PowerMenuState.hide()
            }

            Item {
                id: card
                visible: win.isMain
                width: 1200
                height: 380
                anchors.centerIn: parent
                opacity: 0

                // "erscheint 50ms nach dem Öffnen" -- a State/Transition
                // pair rather than a Connections{ onOpenChanged } handler:
                // the latter only fires on an actual value change, so it
                // would never run for an already-true initial value
                // (memory: feedback_qml_binding_fires_on_init is the
                // mirror-image case of this same "nothing to listen to at
                // construction" trap). `when` is re-evaluated continuously
                // and drives PropertyChanges directly, so it's correct both
                // for a real open-after-closed transition and for a
                // forced-open initial state (screenshot testing, see
                // README "Testmethode").
                states: State {
                    name: "shown"
                    when: PowerMenuState.open && win.isMain
                    PropertyChanges { card.opacity: 1 }
                }
                transitions: [
                    Transition {
                        from: ""; to: "shown"
                        SequentialAnimation {
                            PauseAnimation { duration: 50 }
                            NumberAnimation { target: card; property: "opacity"; duration: Style.animFast }
                        }
                    },
                    Transition {
                        from: "shown"; to: ""
                        NumberAnimation { target: card; property: "opacity"; duration: Style.animFast }
                    }
                ]

                // Swallow clicks on the card itself so they don't fall
                // through to the full-window close-catcher above.
                MouseArea {
                    anchors.fill: parent
                }

                Row {
                    anchors.centerIn: parent
                    spacing: 80

                    Repeater {
                        model: root._enabledOptions

                        // `index` isn't redeclared here -- PowerOption.qml
                        // already has `required property int index`, and
                        // Quickshell auto-injects Repeater's index/modelData
                        // context values into a delegate's own required
                        // properties of matching name. Redeclaring `index`
                        // on this instance would shadow that injection with
                        // a self-referential `index: index` binding that
                        // never resolves (memory:
                        // feedback_qml_child_property_shadows_outer_id).
                        PowerOption {
                            required property var modelData
                            option: modelData
                            selected: index === PowerMenuState.selectedIndex
                            onActivated: root._runSelected()
                        }
                    }
                }
            }

            // Keyboard: <-/-> selects, Enter executes, Esc closes. Only
            // meaningful on the instance actually holding Exclusive focus.
            Item {
                anchors.fill: parent
                focus: PowerMenuState.open && win.isMain
                Keys.onLeftPressed: {
                    if (PowerMenuState.selectedIndex > 0)
                        PowerMenuState.selectedIndex -= 1;
                }
                Keys.onRightPressed: {
                    if (PowerMenuState.selectedIndex < root._enabledOptions.length - 1)
                        PowerMenuState.selectedIndex += 1;
                }
                Keys.onReturnPressed: root._runSelected()
                Keys.onEnterPressed: root._runSelected()
                Keys.onEscapePressed: PowerMenuState.hide()
            }
        }
    }
}
