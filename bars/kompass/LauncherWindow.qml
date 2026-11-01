import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets
import "components"

// Own top-level layer-shell surface for the launcher, instantiated fresh by
// Bar.qml's Loader every time it opens -- not an Item living inside the
// Bar's own always-mapped PanelWindow.
//
// Reason (verified the hard way in bars/fisheye, see its bar/
// LauncherWindow.qml): mango only ever grants keyboard focus to an
// on-demand layer surface at that surface's very first commit, or on a
// pointer click evaluated against a keyboard_interactive state that's
// *already* committed as on-demand. Toggling WlrLayershell.keyboardFocus on
// a long-lived, reused surface (like Bar's) always misses both of those --
// neither typing nor Escape would ever reach this. A brand-new surface's
// initial commit grants focus immediately regardless of which path opened
// it (click or the SUPER+space hotkey), so keyboardFocus is OnDemand from
// the very start here, on a window that only exists while open.
PanelWindow {
    id: root

    required property var modelData
    // Not `closed` -- Window already owns that as its own signal.
    signal closeRequested

    screen: modelData
    color: "transparent"

    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.namespace: "kompass-launcher"
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand

    anchors.top: true
    anchors.left: true
    anchors.right: true
    anchors.bottom: true

    readonly property real _panelWidth: 260
    readonly property real _panelHeight: 300
    readonly property real _restY: Theme.barHeight + 8

    // Full-window click catcher, declared before (so: below in z-order)
    // the panel -- clicks that land on one of the panel's own interactive
    // children (TextInput, result rows) are consumed by those first and
    // never reach this; anything else (outside the panel, or blank panel
    // padding via the swallow MouseArea below) closes the launcher.
    MouseArea {
        anchors.fill: parent
        onClicked: root.closeRequested()
    }

    Rectangle {
        id: panel
        anchors.horizontalCenter: parent.horizontalCenter
        y: root._restY - 10
        width: root._panelWidth
        height: root._panelHeight
        radius: Theme.panelRadius
        color: Theme.panelMetal
        border.color: Theme.rivetDark
        border.width: 1
        opacity: 0

        Component.onCompleted: {
            yAnim.start();
            opAnim.start();
        }
        NumberAnimation {
            id: yAnim
            target: panel
            property: "y"
            to: root._restY
            duration: Theme.durMorph
            easing.type: Theme.easeOutBack
        }
        NumberAnimation {
            id: opAnim
            target: panel
            property: "opacity"
            to: 1
            duration: Theme.durBase
            easing.type: Theme.easeOut
        }

        // Swallows clicks on blank panel padding so they don't fall
        // through to the full-window closer above.
        MouseArea {
            anchors.fill: parent
        }

        Column {
            anchors.fill: parent
            anchors.margins: 10
            spacing: 8

            Row {
                width: parent.width
                spacing: 6

                SearchGlyph {
                    anchors.verticalCenter: parent.verticalCenter
                    color: Theme.panelInk
                }

                Rectangle {
                    width: parent.width - 21
                    height: 26
                    radius: 6
                    color: Theme.dialFace
                    border.color: query.activeFocus ? Theme.accent : Theme.dividerLine
                    border.width: 1
                    Behavior on border.color {
                        ColorAnimation {
                            duration: Theme.durFast
                        }
                    }

                    TextInput {
                        id: query
                        anchors.fill: parent
                        anchors.margins: 6
                        color: Theme.panelInk
                        font.pixelSize: 12
                        clip: true
                        selectByMouse: true

                        Keys.onEscapePressed: root.closeRequested()
                        Keys.onReturnPressed: launcher.launchSelected()
                        Keys.onDownPressed: launcher.selectedIndex = Math.min(launcher.selectedIndex + 1, Math.max(launcher.results.length - 1, 0))
                        Keys.onUpPressed: launcher.selectedIndex = Math.max(launcher.selectedIndex - 1, 0)
                    }
                    Text {
                        anchors.fill: query
                        text: "Suchen…"
                        color: Theme.panelInk
                        opacity: 0.4
                        font.pixelSize: 12
                        visible: query.text.length === 0 && !query.activeFocus
                    }
                }
            }

            Flickable {
                width: parent.width
                height: parent.height - 40
                clip: true
                contentHeight: resultsCol.implicitHeight
                boundsBehavior: Flickable.StopAtBounds

                Column {
                    id: resultsCol
                    width: parent.width
                    spacing: 2

                    Repeater {
                        model: launcher.results
                        delegate: Rectangle {
                            id: row
                            required property var modelData
                            required property int index

                            width: resultsCol.width
                            height: 28
                            radius: 6
                            color: index === launcher.selectedIndex ? Qt.alpha(Theme.accent, 0.22) : "transparent"
                            Behavior on color {
                                ColorAnimation {
                                    duration: Theme.durFast
                                }
                            }

                            Row {
                                anchors.left: parent.left
                                anchors.leftMargin: 6
                                anchors.right: parent.right
                                anchors.rightMargin: 6
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: 6

                                IconImage {
                                    anchors.verticalCenter: parent.verticalCenter
                                    implicitSize: 16
                                    source: Quickshell.hasThemeIcon(row.modelData.icon) ? Quickshell.iconPath(row.modelData.icon) : ""
                                    visible: source !== ""
                                }
                                Text {
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: row.modelData.name
                                    color: Theme.panelInk
                                    font.pixelSize: 12
                                    elide: Text.ElideRight
                                    width: parent.width - 22
                                }
                            }

                            MouseArea {
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onEntered: launcher.selectedIndex = row.index
                                onClicked: {
                                    AppEntries.launch(row.modelData);
                                    root.closeRequested();
                                }
                            }
                        }
                    }

                    Text {
                        visible: AppEntries.ready && launcher.results.length === 0
                        text: "Keine Treffer"
                        color: Theme.panelInk
                        opacity: 0.4
                        font.pixelSize: 11
                    }
                }
            }
        }
    }

    QtObject {
        id: launcher
        property int selectedIndex: 0
        readonly property var results: {
            if (!AppEntries.ready)
                return [];
            const q = query.text.trim().toLowerCase();
            const pool = AppEntries.apps;
            const matched = q.length === 0 ? pool : pool.filter(a => a.name.toLowerCase().includes(q));
            return matched.slice(0, 8);
        }
        onResultsChanged: selectedIndex = 0

        function launchSelected() {
            if (results.length === 0)
                return;
            AppEntries.launch(results[Math.min(selectedIndex, results.length - 1)]);
            root.closeRequested();
        }
    }

    Component.onCompleted: query.forceActiveFocus()
}
