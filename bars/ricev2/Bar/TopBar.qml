import QtQuick
import "../"
import "widgets"
import "menus"
import "lyrics"

// Bar prompt sections 1-4 + menus prompt section 1 + section 6. Stage 1
// built window/island shapes + colors + clock; Stage 2 added the rest of
// the left/right widgets; Stage 3 added the dropdown menus (volume/wifi/
// bluetooth/calendar/weather/notifications); Stage 4 (this revision) adds
// the middle island's lyrics + karaoke effect + cava visualizer.
Item {
    id: root

    readonly property int barHeight: Style.barHeight
    readonly property int slant: Style.diagSlant

    // Exposed so BarShell.qml can build its input mask from real
    // geometry instead of guessing island bounds.
    property alias leftIslandItem: leftIsland
    property alias rightIslandItem: rightIsland
    property alias middleIslandItem: middleIsland
    property alias dropdownItem: dropdown
    property alias leftDropdownItem: leftDropdown

    // Spec section 1: "Barhöhe + höchstes offenes Dropdown + (Visualizer-
    // Höhe, wenn Musik läuft)" -- both extras start from the same y=0
    // origin as the islands, so the window only needs to be as tall as
    // whichever one currently reaches furthest down, not their sum.
    implicitHeight: Math.max(barHeight + dropdown.height, barHeight + leftDropdown.height, middleIsland.height)

    // -- Left island: cpu/gpu/memory ------------------------------------
    Item {
        id: leftIsland
        anchors.left: parent.left
        anchors.top: parent.top
        width: leftContent.width > 0 ? leftContent.width + root.slant + 24 : root.slant + 24
        height: root.barHeight

        Island {
            anchors.fill: parent
            variant: "left"
        }

        // Mouseover-mode widgets (Config per-widget "mouseover" override,
        // none by default) reveal while this island is hovered. Bound to
        // the island's own current geometry, not a separate max-possible-
        // width zone -- spec's "invisible zone in voller möglicher
        // Inselbreite" exists to avoid flicker as mouseover widgets grow
        // the island under a still-held hover; with no mouseover widgets
        // enabled by default there's nothing to observe that flicker
        // against yet, so that refinement is deferred until an actual
        // mouseover-enabled widget needs it.
        HoverHandler {
            id: leftHover
        }

        // Not part of either original prompt (bar prompt's own cpu/gpu/
        // memory click column only says "schließt offenes Dropdown" / "–" --
        // see SysMonitorDropdown.qml's header comment). Sits behind
        // leftContent's Row in paint order but that doesn't matter for hit-
        // testing here: none of cpu/gpu/memory's own widgets have a
        // MouseArea of their own (their click was never wired, same
        // comment), so there's nothing for this to compete with.
        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: DropdownState.toggle("sysmonitor")
        }

        Row {
            id: leftContent
            anchors.left: parent.left
            anchors.leftMargin: 12
            anchors.verticalCenter: parent.verticalCenter
            spacing: 8

            Repeater {
                model: Config.widgetsLeft

                WidgetSlot {
                    required property string modelData
                    widgetId: modelData
                    sideHovered: leftHover.hovered
                }
            }
        }
    }

    // -- Middle island: workspaces (idle) / lyrics + visualizer (stage 4)
    // ------------------------------------------------------------------
    // Content lives in LyricsIsland.qml. Originally this wrapper collapsed
    // to width 0 whenever nothing was playing (see git history / README
    // Stage 4); now the island itself stays permanently visible -- its
    // height still grows by Style.vizHeight while the cava canvas bulges
    // below it during playback, and (new) its width now tracks the same
    // idle/playing split: only as wide as the workspace-pip content while
    // idle, growing to the full lyrics width the moment something actually
    // plays (LyricsService.playing, e.g. a YouTube tab via MPRIS) instead
    // of always sitting at the full 699px. LyricsIsland.qml crossfades its
    // own content between WorkspacePips (idle) and the lyrics layout
    // (playing) and mirrors whatever width this wrapper settles on.
    Item {
        id: middleIsland
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: lyricsContent.musicPlaying ? Style.middleIslandWidth : lyricsContent.idleWidth
        height: lyricsContent.musicPlaying ? root.barHeight + Style.vizHeight : root.barHeight
        Behavior on width {
            NumberAnimation { duration: Style.anim300; easing.type: Easing.OutCubic }
        }
        Behavior on height {
            NumberAnimation { duration: Style.anim200; easing.type: Easing.OutCubic }
        }

        LyricsIsland {
            id: lyricsContent
            anchors.top: parent.top
        }
    }

    // -- Right island: weather/bluetooth/wifi/brightness/battery/volume/
    //    notifications/clock ------------------------------------------
    Item {
        id: rightIsland
        anchors.right: parent.right
        anchors.top: parent.top
        width: rightContent.width > 0 ? rightContent.width + root.slant + 24 : root.slant + 24
        height: root.barHeight

        Island {
            anchors.fill: parent
            variant: "right"
        }

        HoverHandler {
            id: rightHover
        }

        Row {
            id: rightContent
            anchors.right: parent.right
            anchors.rightMargin: 12
            anchors.verticalCenter: parent.verticalCenter
            spacing: 14

            Repeater {
                model: Config.widgetsRight

                WidgetSlot {
                    required property string modelData
                    widgetId: modelData
                    sideHovered: rightHover.hovered
                }
            }
        }
    }

    // -- Dropdown host: right-aligned under the right island -------------
    // Every dropdown (menus prompt section 1) opens from a right-island
    // widget, so they all share this one anchor point; DropdownState.open
    // picks which content Loader is active. Only one can be open at a time.
    readonly property var _dropdownFiles: ({
        volume: "menus/VolumeDropdown.qml",
        wifi: "menus/WifiDropdown.qml",
        bluetooth: "menus/BluetoothDropdown.qml",
        calendar: "menus/CalendarDropdown.qml",
        weather: "menus/WeatherDropdown.qml",
        notifications: "menus/NotificationsDropdown.qml",
        settings: "menus/SettingsDropdown.qml"
    })

    // sysmonitor is the one exception: it opens from the left island, not
    // the right, so it gets its own Dropdown instance below (leftDropdown)
    // instead of going through _dropdownFiles/dropdownItem.
    readonly property bool _rightDropdownOpen: DropdownState.open !== "" && DropdownState.open !== "sysmonitor"

    // Esc closes whichever bar dropdown is currently open -- BarShell.qml
    // switches the whole window to WlrKeyboardFocus.Exclusive while
    // DropdownState.open !== "" specifically so this reliably receives the
    // key (matches Launcher.qml/Switcher.qml/PowerMenu.qml, which already
    // had their own Keys.onEscapePressed via their own Exclusive-while-open
    // windows). Excluded while DropdownState.keyboardWanted (the WLAN
    // PasswordField wants Esc itself, to cancel just the typing -- its own
    // Keys.onEscapePressed) -- so this catcher only reacts once that's
    // false again.
    Item {
        id: dropdownEscCatcher
        anchors.fill: parent
        focus: DropdownState.open !== "" && !DropdownState.keyboardWanted
        Keys.onEscapePressed: DropdownState.close()

        // PasswordField.qml grabs focus imperatively via
        // hiddenInput.forceActiveFocus() when it opens, which breaks this
        // Item's own `focus` binding above (an engine-driven focus change
        // clears the previous holder's `focus` property, turning the
        // binding into a dead literal `false`). Re-claim focus explicitly,
        // the same way, once keyboardWanted drops back to false (password
        // cancelled/submitted) instead of relying on that binding to fire
        // again on its own.
        Connections {
            target: DropdownState
            function onKeyboardWantedChanged() {
                if (!DropdownState.keyboardWanted && DropdownState.open !== "")
                    dropdownEscCatcher.forceActiveFocus();
            }
        }
    }

    Dropdown {
        id: dropdown
        anchors.top: rightIsland.bottom
        anchors.right: rightIsland.right
        open: root._rightDropdownOpen
        alpha: DropdownState.open === "notifications" ? Style.notificationAlpha : Style.islandAlpha

        Loader {
            active: root._rightDropdownOpen
            source: root._dropdownFiles[DropdownState.open] || ""
        }
    }

    // Left-island counterpart to the dropdown host above -- only
    // sysmonitor uses this for now. Flush-left under the left island, per
    // the bar prompt's own (until now unused) dropdown-position line
    // ("linke Seite bündig links"; the right side's own line -- "horizontal
    // unter dem geklickten Widget zentriert, an den Rändern geklemmt" --
    // only applies there since the right island holds multiple independent
    // dropdown triggers where "under the clicked widget" is meaningful; the
    // left island has exactly one, so flush-left under the whole island is
    // the same thing without extra positioning math).
    Dropdown {
        id: leftDropdown
        anchors.top: leftIsland.bottom
        anchors.left: leftIsland.left
        open: DropdownState.open === "sysmonitor"

        Loader {
            active: DropdownState.open === "sysmonitor"
            source: "menus/SysMonitorDropdown.qml"
        }
    }
}
