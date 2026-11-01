import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland

// One bar per screen. The window itself is bigger than the visible bar
// strip so it can host any open liquid menu flowing out past that strip;
// exclusiveZone only reserves the strip itself so open menus float over
// windows instead of pushing them down.
//
// The bar can dock to any screen edge (Settings.barPosition). Only the
// dimension away from the docked edge is "extra" window space for menus to
// grow into; the dimension along the edge always spans the full screen.
PanelWindow {
    id: bar

    required property var modelData
    screen: modelData

    readonly property string bp: Settings.barPosition
    readonly property bool vertical: Settings.vertical
    readonly property int thickness: Settings.barThickness
    // Budget for a fully open liquid menu growing away from the bar edge
    // (menus scale up to 1.2x their base size on vertical bars, see
    // LiquidMenu.qml's effMenuContentHeight). SettingsMenu's Monitor tab is
    // the tallest menu (menuContentHeight 480 * 1.2 = 576 on a vertical bar).
    readonly property int maxMenuHeight: 620

    // Where the visible bar strip sits inside this (possibly larger) window.
    readonly property int stripX: bp === "right" ? bar.width - thickness : 0
    readonly property int stripY: bp === "bottom" ? bar.height - thickness : 0
    readonly property int stripW: vertical ? thickness : bar.width
    readonly property int stripH: vertical ? bar.height : thickness

    readonly property int endMargin: 10

    color: Theme.barBg
    focusable: true
    exclusionMode: ExclusionMode.Normal
    exclusiveZone: thickness
    // Whichever dimension isn't pinned by anchors on both sides picks up
    // this implicit size; the other is ignored since anchors already fix it.
    implicitWidth: thickness + maxMenuHeight
    implicitHeight: thickness + maxMenuHeight

    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.namespace: "mangobar"
    // OnDemand alone isn't reliably honored by mango for a layer-shell
    // surface that isn't already focused (typed keys kept going to the
    // toplevel underneath). Grab keyboard focus explicitly only while a menu
    // that can take typed input is actually open (the launcher, the settings
    // menu -- WLAN password field -- or the command editor modal), and give
    // it back the instant it closes.
    WlrLayershell.keyboardFocus: (clockMenu.open || settingsMenu.open || sysMon.open || ShortcutsEditor.open) ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    // Liquid menus no longer auto-close on unhover (see LiquidMenu.qml) --
    // this is what closes them now instead: any click outside every open
    // menu's own shape, or Escape.
    readonly property bool anyMenuOpen: settingsMenu.open || clockMenu.open || sysMon.open

    anchors {
        top: bp === "top" || bp === "left" || bp === "right"
        bottom: bp === "bottom" || bp === "left" || bp === "right"
        left: bp === "top" || bp === "bottom" || bp === "left"
        right: bp === "top" || bp === "bottom" || bp === "right"
    }

    // Only the bar strip + whichever liquid menu is currently open should
    // receive input; everywhere else clicks/hover must pass through to the
    // windows below. Each hitArea shrinks to zero size when its menu is
    // closed, so this mask updates itself automatically.
    mask: Region {
        Region { item: barStrip }
        Region { item: settingsMenu.hitArea }
        Region { item: clockMenu.hitArea }
        Region { item: sysMon.hitArea }
        Region { item: scriptEditorBackdrop }
        Region { item: chessWindow }
        // While any liquid menu is open, the whole window becomes clickable
        // so dismissCatcher below can see clicks that land outside every
        // open menu's own shape (still within the bar's reserved space) and
        // close them. Zero-size (no-op) while nothing is open, same as the
        // per-menu hitAreas above.
        Region {
            x: 0
            y: 0
            width: bar.anyMenuOpen ? bar.width : 0
            height: bar.anyMenuOpen ? bar.height : 0
        }
    }

    Item {
        id: barStrip
        x: bar.stripX
        y: bar.stripY
        width: bar.stripW
        height: bar.stripH
    }

    Rectangle {
        id: barBackground
        x: bar.stripX
        y: bar.stripY
        width: bar.stripW
        height: bar.stripH
        color: Theme.surface
        z: 0
    }

    // Click-away / Esc dismissal for menus that no longer auto-close on
    // unhover. z:0 keeps it below the trigger groups (z:1) and the menu
    // overlay (z:500), so it only ever catches clicks that miss both.
    // clockMenu is deliberately left out of the focus grab -- the launcher
    // search field (Launcher.qml) already owns its own focus and Escape
    // handling independently; claiming focus here too would race it, the
    // same bug already fixed once in the quickdots menu itself.
    Item {
        id: dismissCatcher
        anchors.fill: parent
        focus: settingsMenu.open || sysMon.open
        Keys.onEscapePressed: {
            settingsMenu.close();
            clockMenu.close();
            sysMon.close();
        }

        MouseArea {
            anchors.fill: parent
            enabled: bar.anyMenuOpen
            onClicked: {
                settingsMenu.close();
                clockMenu.close();
                sysMon.close();
            }
        }
    }

    // -- start / middle / end groups along the bar's length axis --
    // Horizontal: left / center / right. Vertical: top / middle / bottom.
    // Which modules land in which group differs by orientation (see the
    // `parent:` bindings on Tags/Clock below) to match the requested
    // vertical arrangement: clock at the start, tags in the middle, the
    // sysmon/volume/tray cluster at the end.

    GridLayout {
        id: startGroup
        z: 1
        flow: bar.vertical ? GridLayout.TopToBottom : GridLayout.LeftToRight
        rows: bar.vertical ? -1 : 1
        columns: bar.vertical ? 1 : -1
        rowSpacing: 10
        columnSpacing: 10
        // No margin toward (0,0): the settings trigger needs to reach all
        // the way into the strip's literal starting corner, or hovering
        // the very corner misses it.
        x: bar.stripX
        y: bar.stripY
        width: bar.vertical ? bar.stripW : implicitWidth
        height: bar.vertical ? implicitHeight : bar.stripH

        SettingsMenu {
            id: settingsMenu
            menuLayer: overlay
        }
    }

    GridLayout {
        id: middleGroup
        z: 1
        flow: bar.vertical ? GridLayout.TopToBottom : GridLayout.LeftToRight
        rows: bar.vertical ? -1 : 1
        columns: bar.vertical ? 1 : -1
        x: bar.vertical ? bar.stripX : Math.round((bar.width - implicitWidth) / 2)
        y: bar.vertical ? Math.round((bar.height - implicitHeight) / 2) : bar.stripY
        width: bar.vertical ? bar.stripW : implicitWidth
        height: bar.vertical ? implicitHeight : bar.stripH
    }

    GridLayout {
        id: endGroup
        z: 1
        flow: bar.vertical ? GridLayout.TopToBottom : GridLayout.LeftToRight
        rows: bar.vertical ? -1 : 1
        columns: bar.vertical ? 1 : -1
        rowSpacing: 14
        columnSpacing: 14
        x: bar.vertical ? bar.stripX : bar.width - implicitWidth - bar.endMargin
        y: bar.vertical ? bar.height - implicitHeight - bar.endMargin : bar.stripY
        width: bar.vertical ? bar.stripW : implicitWidth
        height: bar.vertical ? implicitHeight : bar.stripH

        SysMon {
            id: sysMon
            menuLayer: overlay
        }

        Volume {}

        Tray {
            hostWindow: bar
        }
    }

    // Tags and Clock swap between the start/middle groups depending on
    // orientation: left→right bar has [settings, tags] / [clock], while a
    // vertical bar wants [settings, clock] on top and [tags] centered.
    Tags {
        id: tags
        outputName: bar.screen ? bar.screen.name : ""
        parent: bar.vertical ? middleGroup : startGroup

        // Vertical mode moves the launcher's open-gesture here instead of
        // the clock (see Clock.qml's triggerHoverEnabled).
        HoverHandler {
            id: tagsHover
            onHoveredChanged: clockMenu.externalHover = bar.vertical && tagsHover.hovered
        }
    }

    Clock {
        id: clockMenu
        menuLayer: overlay
        parent: bar.vertical ? startGroup : middleGroup
        // The clock trigger sits at the very top of a vertical bar, but its
        // launcher popup should open level with the workspace dots instead.
        alignTarget: bar.vertical ? tags : null
    }

    // Floating liquid-menu shapes are reparented in here; it sits above
    // everything else so a dropped-down menu is never occluded.
    Item {
        id: overlay
        anchors.fill: parent
        z: 500
    }

    // Big centered "add/edit command" modal for the settings menu's
    // Commands tab, opened via the ShortcutsEditor singleton. Sits above
    // the overlay (and thus above any open liquid menu) since it dims the
    // whole window while active. Sized 0x0 when closed -- like LiquidMenu's
    // hitArea -- so Bar.qml's input mask (above) shrinks to nothing along
    // with it instead of eating clicks over the rest of the screen.
    Rectangle {
        id: scriptEditorBackdrop
        x: 0
        y: 0
        width: ShortcutsEditor.open ? bar.width : 0
        height: ShortcutsEditor.open ? bar.height : 0
        clip: true
        z: 2000
        color: "transparent"
        visible: width > 0 && height > 0

        onVisibleChanged: {
            if (visible) {
                editorNameField.text = ShortcutsEditor.name;
                editorScriptField.text = ShortcutsEditor.script;
                editorNameField.forceActiveFocus();
            }
        }

        // Swallows clicks/hover so nothing behind the modal reacts while open.
        MouseArea { anchors.fill: parent; hoverEnabled: true }

        Rectangle {
            id: scriptEditorPanel
            anchors.centerIn: parent
            width: Math.min(560, parent.width - 60)
            height: Math.min(520, parent.height - 60)
            radius: 16
            color: Theme.surface
            border.color: Qt.alpha(Theme.mutedText, 0.25)
            border.width: 1

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 18
                spacing: 10

                Text {
                    text: ShortcutsEditor.index >= 0 ? "Edit Command" : "New Command"
                    color: Theme.foreground
                    font.pixelSize: 15
                    font.bold: true
                }

                Rectangle {
                    Layout.fillWidth: true
                    height: 32
                    radius: 8
                    color: Qt.alpha(Theme.mutedText, 0.12)

                    TextInput {
                        id: editorNameField
                        anchors.fill: parent
                        anchors.margins: 8
                        color: Theme.foreground
                        font.pixelSize: 13
                        clip: true
                        Keys.onEscapePressed: ShortcutsEditor.close()
                        Keys.onReturnPressed: editorScriptField.forceActiveFocus()
                        Keys.onEnterPressed: editorScriptField.forceActiveFocus()
                    }
                    Text {
                        anchors.fill: editorNameField
                        anchors.margins: 8
                        text: "Name"
                        color: Theme.mutedText
                        font.pixelSize: 13
                        visible: editorNameField.text.length === 0
                    }
                }

                Text { text: "Script"; color: Theme.mutedText; font.pixelSize: 11 }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    radius: 8
                    color: Qt.alpha(Theme.mutedText, 0.12)

                    Flickable {
                        anchors.fill: parent
                        anchors.margins: 8
                        clip: true
                        contentWidth: width
                        contentHeight: Math.max(height, editorScriptField.implicitHeight)

                        TextEdit {
                            id: editorScriptField
                            width: parent.width
                            color: Theme.foreground
                            font.pixelSize: 13
                            font.family: "monospace"
                            wrapMode: TextEdit.NoWrap
                            selectByMouse: true
                            persistentSelection: true
                            Keys.onEscapePressed: ShortcutsEditor.close()
                        }
                    }

                    Text {
                        anchors.top: parent.top
                        anchors.left: parent.left
                        anchors.margins: 8
                        text: "one command per line…"
                        color: Theme.mutedText
                        font.pixelSize: 13
                        font.family: "monospace"
                        visible: editorScriptField.text.length === 0
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8

                    Rectangle {
                        Layout.fillWidth: true
                        height: 30
                        radius: 8
                        color: cancelArea.containsMouse ? Qt.alpha(Theme.mutedText, 0.2) : Qt.alpha(Theme.mutedText, 0.12)
                        Text { anchors.centerIn: parent; text: "Cancel"; color: Theme.foreground; font.pixelSize: 12 }
                        MouseArea {
                            id: cancelArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: ShortcutsEditor.close()
                        }
                    }
                    Rectangle {
                        Layout.fillWidth: true
                        height: 30
                        radius: 8
                        color: saveArea.containsMouse ? Qt.alpha(Theme.accent, 0.4) : Qt.alpha(Theme.accent, 0.25)
                        Text { anchors.centerIn: parent; text: "Save"; color: Theme.foreground; font.pixelSize: 12 }
                        MouseArea {
                            id: saveArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                const n = editorNameField.text.trim();
                                const s = editorScriptField.text.trim();
                                if (ShortcutsEditor.index >= 0) {
                                    Shortcuts.updateAt(ShortcutsEditor.index, n, s);
                                } else {
                                    Shortcuts.add(n, s);
                                }
                                ShortcutsEditor.close();
                            }
                        }
                    }
                }
            }
        }
    }

    ChessWindow {
        id: chessWindow
        hostWindow: bar
        z: 2000
    }
}
