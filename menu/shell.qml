import QtQuick
import QtQuick.Controls
import QtQuick.Effects
import Quickshell
import Quickshell.Wayland
import Quickshell.Io
// steps/ + tabs/ are loaded by URL, but Quickshell only registers the types
// of directories it reaches through imports -- without these, tabs/CustomTab
// can't resolve custom/*.qml ("CustomBarCard is not a type").
import "components"
import "steps"
import "tabs"

ShellRoot {
    id: root

    // Both popups stay mapped for a little longer than MenuState/SearchState
    // .visible so their own close animation (opacity/scale/y Behaviors
    // below) gets to actually play instead of being cut off by the
    // layer-shell surface disappearing instantly.
    property bool menuMapped: false
    property bool searchMapped: false

    Timer { id: menuUnmapTimer; interval: 230; onTriggered: root.menuMapped = false }
    Timer { id: searchUnmapTimer; interval: 230; onTriggered: root.searchMapped = false }

    // External trigger for the mango keybind:
    // qs -p ~/quickdots/menu ipc call menu toggle
    IpcHandler {
        target: "menu"
        function toggle(): void { MenuState.toggle(); }
        function open(): void { MenuState.open(); }
        function close(): void { MenuState.close(); }
    }

    // Same menu under the wizard name, plus tab navigation:
    // qs -p ~/quickdots/menu ipc call wizard toggle
    // qs -p ~/quickdots/menu ipc call wizard tab 0
    // qs -p ~/quickdots/menu ipc call wizard select polarlicht
    // qs -p ~/quickdots/menu ipc call wizard apply
    // qs -p ~/quickdots/menu ipc call wizard blob
    // qs -p ~/quickdots/menu ipc call wizard widgets
    // qs -p ~/quickdots/menu ipc call wizard blur
    IpcHandler {
        target: "wizard"
        function toggle(): void { MenuState.toggle(); }
        function open(): void { MenuState.open(); }
        function close(): void { Wizard.close(); }
        function next(): void { Wizard.nextTab(); }
        function back(): void { Wizard.prevTab(); }
        function tab(i: int): void { Wizard.goTo(i); }
        function select(bar: string): void { Wizard.selectedBar = bar; }
        function apply(): void { Wizard.apply(); }
        function launcher(id: string): void { Wizard.selectedLauncher = id; }
        // Open (or switch to) the "Blob" tab -- bound to CTRL+Shift_R.
        function blob(): void { Wizard.openAt("blob"); }
        // Open (or switch to) the "Widgets" tab.
        function widgets(): void { Wizard.openAt("widgets"); }
        // Open (or switch to) the "Server" tab.
        function server(): void { Wizard.openAt("server"); }
        // Open (or switch to) the "Blur" tab.
        function blur(): void { Wizard.openAt("blur"); }
    }

    // Second, independent trigger for the app search popup (SUPER+space):
    // qs -p ~/quickdots/menu ipc call launcher toggle
    // No-ops (see SearchState.qml) unless the app search is the launcher in
    // use for the active bar (LauncherStore, "Launcher" tab).
    IpcHandler {
        target: "launcher"
        function toggle(): void { SearchState.toggle(); }
        function open(): void { SearchState.open(); }
        function close(): void { SearchState.close(); }
    }

    // Outside-click catcher, same pattern as quickbar/shell.qml: fullscreen,
    // no exclusive zone, click-through unless the menu is open.
    PanelWindow {
        id: catcher
        visible: root.menuMapped
        anchors { top: true; bottom: true; left: true; right: true }
        color: "transparent"

        // Top, strictly below the panel's own Overlay -- same-layer
        // stacking between two separate surfaces isn't guaranteed by the
        // compositor (see bars/floating/IslandBase.qml's comment on this
        // exact issue), so a same-layer catcher can end up rendering ABOVE
        // the panel and swallow every click before it reaches any button
        // inside it. A strictly lower layer makes the panel win
        // deterministically, regardless of mapping order.
        WlrLayershell.layer: WlrLayer.Top
        WlrLayershell.namespace: "quickdots-menu-catcher"
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
        exclusiveZone: 0

        MouseArea {
            anchors.fill: parent
            onClicked: MenuState.close()
        }
    }

    PanelWindow {
        id: win
        visible: root.menuMapped
        anchors { top: true; bottom: true; left: true; right: true }
        color: "transparent"

        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: "quickdots-menu"
        WlrLayershell.keyboardFocus: MenuState.visible ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
        exclusiveZone: 0

        mask: Region {
            x: panel.x
            y: panel.y
            width: panel.width
            height: panel.height
            topLeftRadius: Theme.radius
            topRightRadius: Theme.radius
            bottomLeftRadius: Theme.radius
            bottomRightRadius: Theme.radius
        }

        // Wizard window (Calamares-style). The layer-shell surface is
        // fullscreen, so "moving" (title bar drag), "resizing" (corner grip)
        // and "maximizing" just change this Item's geometry inside it.
        Item {
            id: panel

            property bool maximized: false
            property real userW: Theme.windowWidth
            property real userH: Theme.windowHeight
            property real offX: 0
            property real offY: 0

            readonly property real maxW: parent.width - 2 * Theme.maximizedMargin
            readonly property real maxH: parent.height - 2 * Theme.maximizedMargin

            width: maximized ? maxW : Math.min(userW, maxW)
            height: maximized ? maxH : Math.min(userH, maxH)
            x: maximized ? Theme.maximizedMargin
                         : Math.max(0, Math.min(parent.width - width, (parent.width - width) / 2 + offX))
            y: maximized ? Theme.maximizedMargin
                         : Math.max(0, Math.min(parent.height - height, (parent.height - height) / 2 + offY))

            opacity: MenuState.visible ? 1 : 0
            scale: MenuState.visible ? 1 : 0.96

            Behavior on width { enabled: !resizeGrip.pressed; NumberAnimation { duration: Theme.animWindow; easing.type: Easing.OutCubic } }
            Behavior on height { enabled: !resizeGrip.pressed; NumberAnimation { duration: Theme.animWindow; easing.type: Easing.OutCubic } }
            Behavior on opacity { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
            Behavior on scale { NumberAnimation { duration: Theme.animWindow; easing.type: Easing.OutBack; easing.overshoot: 1.15 } }

            // Keys bubble up here from the focused tab (the Bars list keeps
            // ↑/↓ for itself, text fields in the editor keep ←/→):
            // ←/→ = switch tab, Enter = Anwenden (Bars/Launcher tab), Esc = close.
            // A text field at its start/end lets ←/→ bubble too -- don't
            // switch tabs from inside one that has text (an empty one, like
            // the Bars search when nothing is typed, still switches).
            readonly property bool typing: Window.activeFocusItem !== null
                && Window.activeFocusItem.cursorPosition !== undefined
                && Window.activeFocusItem.text.length > 0
            Keys.onPressed: event => {
                if (event.key === Qt.Key_Escape) { Wizard.close(); event.accepted = true; }
                else if (event.key === Qt.Key_Left && !typing) { Wizard.prevTab(); event.accepted = true; }
                else if (event.key === Qt.Key_Right && !typing) { Wizard.nextTab(); event.accepted = true; }
                else if ((event.key === Qt.Key_Return || event.key === Qt.Key_Enter) && (Wizard.currentId === "bar" || Wizard.currentId === "launcher")) { Wizard.apply(); event.accepted = true; }
            }

            // Background + soft shadow (shadow only on this plain rect, not
            // on the whole content, so nothing heavy gets re-rendered).
            Rectangle {
                id: windowBg
                anchors.fill: parent
                radius: Theme.radius
                color: Theme.bg
                border.width: Theme.borderWidth
                border.color: Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.35)
                layer.enabled: true
                layer.effect: MultiEffect {
                    shadowEnabled: true
                    shadowColor: Theme.shadow
                    shadowBlur: 1.0
                    shadowVerticalOffset: 8
                    blurMax: 48
                }
            }

            TitleBar {
                id: titleBar
                anchors { top: parent.top; left: parent.left; right: parent.right; margins: Theme.borderWidth }
                title: "quickdots  ·  " + Wizard.tabs[Wizard.currentTab].label
                maximized: panel.maximized
                onMinimizeRequested: Wizard.close()
                onMaximizeRequested: panel.maximized = !panel.maximized
                onCloseRequested: Wizard.close()
                onDragged: (dx, dy) => {
                    if (panel.maximized) return;
                    panel.offX += dx;
                    panel.offY += dy;
                }
            }

            // -- Page stack -------------------------------------------
            StackView {
                id: stack
                anchors {
                    top: titleBar.bottom; left: parent.left; right: parent.right; bottom: buttonRow.top
                    topMargin: Theme.spacingL; leftMargin: Theme.spacingL; rightMargin: Theme.spacingL; bottomMargin: Theme.spacingM
                }
                clip: true
                // No initialItem: created while the window is still unmapped
                // it stays blank. The page is built on every open instead.

                readonly property real slide: 60 * Wizard.direction
                replaceEnter: Transition {
                    ParallelAnimation {
                        NumberAnimation { property: "x"; from: stack.slide; to: 0; duration: Theme.animPage; easing.type: Easing.OutCubic }
                        NumberAnimation { property: "opacity"; from: 0; to: 1; duration: Theme.animPage; easing.type: Easing.OutCubic }
                    }
                }
                replaceExit: Transition {
                    ParallelAnimation {
                        NumberAnimation { property: "x"; from: 0; to: -stack.slide; duration: Theme.animPage; easing.type: Easing.InCubic }
                        NumberAnimation { property: "opacity"; from: 1; to: 0; duration: Theme.animPage; easing.type: Easing.InCubic }
                    }
                }

                function show(i, immediate) {
                    const url = Qt.resolvedUrl("steps/" + Wizard.tabs[i].file);
                    stack.replace(url, {}, immediate ? StackView.Immediate : StackView.Transition);
                    if (stack.currentItem) stack.currentItem.forceActiveFocus();
                }

                Connections {
                    target: Wizard
                    function onCurrentTabChanged(): void {
                        if (MenuState.visible) stack.show(Wizard.currentTab, false);
                    }
                }
            }

            // -- Status + buttons ------------------------------------
            Item {
                id: buttonRow
                anchors { left: parent.left; right: parent.right; bottom: tabBar.top; leftMargin: Theme.spacingL; rightMargin: Theme.spacingL; bottomMargin: Theme.spacingM }
                height: Theme.buttonHeight

                // Key hints, or the progress/result of the last switch (or,
                // in the Launcher tab, of the last launcher assignment).
                Row {
                    id: statusRow
                    anchors.left: parent.left
                    anchors.right: buttons.left
                    anchors.rightMargin: Theme.spacingM
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: Theme.spacingS

                    readonly property string target: SwitchState.targetBar
                    readonly property bool launcherStatus: LauncherStore.started
                        && (Wizard.currentId === "launcher" || LauncherStore.running)
                    readonly property bool running: launcherStatus ? LauncherStore.running : SwitchState.running
                    readonly property bool done: launcherStatus ? LauncherStore.done : SwitchState.done
                    readonly property bool failed: launcherStatus ? LauncherStore.failed : SwitchState.failed
                    readonly property bool started: launcherStatus || SwitchState.started

                    Spinner {
                        anchors.verticalCenter: parent.verticalCenter
                        visible: statusRow.running
                        running: visible
                        size: Theme.fontS
                    }
                    Icon {
                        anchors.verticalCenter: parent.verticalCenter
                        visible: statusRow.done
                        text: statusRow.failed ? "\uf00d" : "\uf00c"
                        color: statusRow.failed ? Theme.danger : Theme.success
                        size: Theme.fontS
                    }
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        width: parent.width - x
                        elide: Text.ElideRight
                        text: {
                            if (statusRow.launcherStatus) {
                                const what = "„" + LauncherStore.nameOf(LauncherStore.targetLauncher) + "“ für „" + LauncherStore.targetBar + "“";
                                if (LauncherStore.running)
                                    return "Launcher " + what + " … "
                                        + (LauncherStore.currentStep >= 0 ? LauncherStore.stepLabels[LauncherStore.currentStep] : "");
                                if (LauncherStore.failed) {
                                    const errs = LauncherStore.log.filter(l => l.error);
                                    return "Launcher " + what + " fehlgeschlagen (Exit " + LauncherStore.exitCode + ")"
                                        + (errs.length ? ":  " + errs[errs.length - 1].text : "");
                                }
                                return "Launcher " + what + " gespeichert"
                                    + (LauncherStore.targetBar === BarsModel.activeBar ? " und aktiv" : "  ·  aktiv, sobald die Bar gewählt wird");
                            }
                            if (SwitchState.running)
                                return "Wechsel zu „" + parent.target + "“ … "
                                    + (SwitchState.currentStep >= 0 ? SwitchState.stepLabels[SwitchState.currentStep] : "");
                            if (SwitchState.done && SwitchState.failed) {
                                const errs = SwitchState.log.filter(l => l.error && !l.text.startsWith("✗"));
                                return "Wechsel zu „" + parent.target + "“ fehlgeschlagen (Exit " + SwitchState.exitCode + ")"
                                    + (errs.length ? ":  " + errs[errs.length - 1].text : "");
                            }
                            if (SwitchState.done)
                                return "„" + parent.target + "“ ist jetzt aktiv";
                            if (Wizard.currentId === "bar")
                                return "←/→ Tab   ·   ↑/↓ Bar wählen   ·   Enter Anwenden   ·   Esc Schließen";
                            if (Wizard.currentId === "launcher")
                                return "←/→ Tab   ·   ↑/↓ Launcher wählen   ·   Enter für „" + BarsModel.activeBar + "“ übernehmen   ·   Esc Schließen";
                            if (Wizard.currentId === "blob")
                                return "←/→ Tab   ·   Änderungen wirken sofort am Blob   ·   Esc Schließen";
                            if (Wizard.currentId === "blur")
                                return "←/→ Tab   ·   Änderungen wirken sofort (Mango lädt die Config neu)   ·   Esc Schließen";
                            if (Wizard.currentId === "widgets")
                                return "←/→ Tab   ·   ↑/↓ Widget   ·   Leertaste an/aus   ·   V Verschieben   ·   wirkt sofort   ·   Esc Schließen";
                            if (Wizard.currentId === "server")
                                return "←/→ Tab   ·   T Terminal   ·   R Neu verbinden   ·   aktualisiert alle 3 s   ·   Esc Schließen";
                            return "←/→ Tab   ·   Esc Schließen";
                        }
                        color: statusRow.failed ? Theme.danger
                             : statusRow.started ? Theme.text : Theme.textFaint
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontS
                    }
                }

                Row {
                    id: buttons
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: Theme.spacingS

                    WizardButton {
                        visible: Wizard.currentId === "launcher"
                        text: "Ausprobieren"
                        icon: "\uf04b"
                        enabled: Wizard.selectedLauncher.length > 0 && !Wizard.locked
                        onClicked: Wizard.tryLauncher()
                    }
                    WizardButton {
                        visible: Wizard.currentId === "bar" || Wizard.currentId === "launcher"
                        text: "Anwenden"
                        icon: "\uf0e7"
                        primary: true
                        enabled: Wizard.canApply
                        onClicked: Wizard.apply()
                    }
                    WizardButton {
                        text: "Schließen"
                        icon: "\uf00d"
                        onClicked: Wizard.close()
                    }
                }
            }

            // -- Tab bar ----------------------------------------------
            Rectangle {
                id: tabBar
                anchors { left: parent.left; right: parent.right; bottom: parent.bottom; margins: Theme.borderWidth }
                height: Theme.stepBarHeight
                radius: Theme.radius
                color: Theme.titleBar

                // Square off the top corners.
                Rectangle {
                    anchors { left: parent.left; right: parent.right; top: parent.top }
                    height: parent.radius
                    color: parent.color
                }
                Rectangle {
                    anchors { left: parent.left; right: parent.right; top: parent.top }
                    height: 1
                    color: Theme.border
                }

                MenuTabs {
                    anchors.fill: parent
                    anchors.leftMargin: Theme.spacingS
                    anchors.rightMargin: Theme.spacingS
                }
            }

            // -- Resize grip (bottom right) ---------------------------
            MouseArea {
                id: resizeGrip
                visible: !panel.maximized
                anchors { right: parent.right; bottom: parent.bottom }
                width: 16; height: 16
                cursorShape: Qt.SizeFDiagCursor
                property point last
                onPressed: mouse => last = mapToGlobal(mouse.x, mouse.y)
                onPositionChanged: mouse => {
                    if (!pressed) return;
                    const p = mapToGlobal(mouse.x, mouse.y);
                    // Centered window: growing by d keeps the grip under the
                    // cursor when the offset also moves by d/2.
                    const nw = Math.max(860, Math.min(panel.maxW, panel.userW + p.x - last.x));
                    const nh = Math.max(520, Math.min(panel.maxH, panel.userH + p.y - last.y));
                    panel.offX += (nw - panel.userW) / 2;
                    panel.offY += (nh - panel.userH) / 2;
                    panel.userW = nw;
                    panel.userH = nh;
                    last = p;
                }

                Canvas {
                    anchors.fill: parent
                    anchors.margins: 3
                    onPaint: {
                        const c = getContext("2d");
                        c.strokeStyle = Theme.textFaint;
                        c.lineWidth = 1;
                        for (let i = 0; i < 3; i++) {
                            c.beginPath();
                            c.moveTo(width, 3 + i * 3.5);
                            c.lineTo(3 + i * 3.5, height);
                            c.stroke();
                        }
                    }
                }
            }
        }
    }

    Connections {
        target: MenuState
        function onVisibleChanged(): void {
            if (MenuState.visible) {
                menuUnmapTimer.stop();
                root.menuMapped = true;
                BarsModel.rescan();
                BarInfo.rescan();
                CustomBarsStore.refresh();
                BlobStore.refresh();
                WidgetsStore.refresh();
                BlurStore.refresh();
                BlobStore.menuVisible(true);
                Wizard.handleOpen();
                panel.forceActiveFocus();
                stack.show(Wizard.currentTab, true);
            } else {
                menuUnmapTimer.restart();
                BlobStore.menuVisible(false);
            }
        }
    }

    // Standalone app search popup -- deliberately its own window, not a tab
    // in the panel above, since it needs to pop up on its own (SUPER+space)
    // independent of the Bars-switch menu. Same live theme (ThemeAdapter)
    // so it always matches whichever bar is active; SearchState itself
    // refuses to open when that bar already has its own launcher.
    PanelWindow {
        id: searchCatcher
        visible: root.searchMapped
        anchors { top: true; bottom: true; left: true; right: true }
        color: "transparent"

        // Same reasoning as the "quickdots-menu-catcher" above: strictly
        // below searchWin's Overlay layer so stacking is deterministic.
        WlrLayershell.layer: WlrLayer.Top
        WlrLayershell.namespace: "quickdots-launcher-catcher"
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
        exclusiveZone: 0

        MouseArea {
            anchors.fill: parent
            onClicked: SearchState.close()
        }
    }

    PanelWindow {
        id: searchWin
        visible: root.searchMapped
        anchors { top: true; bottom: true; left: true; right: true }
        color: "transparent"

        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: "quickdots-launcher"
        WlrLayershell.keyboardFocus: SearchState.visible ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
        exclusiveZone: 0

        mask: Region {
            x: searchPanel.x
            y: searchPanel.y
            width: searchPanel.width
            height: searchPanel.height
            topLeftRadius: ThemeAdapter.radius
            topRightRadius: ThemeAdapter.radius
            bottomLeftRadius: ThemeAdapter.radius
            bottomRightRadius: ThemeAdapter.radius
        }

        Rectangle {
            id: searchPanel
            anchors.horizontalCenter: parent.horizontalCenter
            y: parent.height * 0.28 + (SearchState.visible ? 0 : -16)
            width: 480
            height: 420
            radius: ThemeAdapter.radius
            color: Qt.rgba(Qt.color(ThemeAdapter.surface).r, Qt.color(ThemeAdapter.surface).g, Qt.color(ThemeAdapter.surface).b, ThemeAdapter.barOpacity)
            border.width: 1
            border.color: Qt.rgba(1, 1, 1, 0.08)
            opacity: SearchState.visible ? 1 : 0
            scale: SearchState.visible ? 1 : 0.94

            Behavior on color { ColorAnimation { duration: 250 } }
            Behavior on radius { NumberAnimation { duration: 250 } }
            Behavior on opacity { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }
            Behavior on scale { NumberAnimation { duration: 230; easing.type: Easing.OutBack; easing.overshoot: 1.2 } }
            Behavior on y { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }

            AppSearch {
                id: appSearch
                anchors.fill: parent
                anchors.margins: 16
            }
        }
    }

    Connections {
        target: SearchState
        function onVisibleChanged(): void {
            if (SearchState.visible) {
                searchUnmapTimer.stop();
                root.searchMapped = true;
                appSearch.forceActiveFocus();
            } else {
                searchUnmapTimer.restart();
            }
        }
    }
}
