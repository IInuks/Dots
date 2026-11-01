import QtQuick
import Quickshell
import Quickshell.Wayland
import "./Bar"

// Own layer-shell surface, created fresh by shell.qml's Loader on every
// open and destroyed on close -- deliberately NOT a long-lived surface
// with `visible` toggled on demand the way the six pill panels in Bar.qml
// are (those stay mapped the whole session, only opacity/height animate).
//
// Reason: mango only grants WlrKeyboardFocus.OnDemand at a surface's very
// first commit, or on a pointer click evaluated against a surface *already*
// committed as on-demand (memory: feedback_mango_ondemand_focus_requires_
// fresh_surface). Bar.qml's own pill panels satisfy this because their
// surface's initial_commit already carries OnDemand from shell startup,
// and every subsequent open is triggered by a click on that same already-
// on-demand surface. The launcher has neither: it's opened by mango's
// SUPER+space keybind -- a dispatch call, not a pointer click -- so the
// "click on an already-committed surface" path can never fire for it. The
// only path left is a fresh initial_commit on every single open, which
// means a fresh surface every time. Exact same conclusion already reached
// (and shipped) in bars/fisheye/bar/LauncherWindow.qml.
PanelWindow {
    id: root

    required property string screenName
    // Not named `closed` -- Window already declares that as its own
    // property-change signal, and QML rejects redeclaring it.
    signal closeRequested

    screen: Quickshell.screens.find(s => s.name === root.screenName) || Quickshell.screens[0]
    color: "transparent"

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "lucid-launcher"
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand

    // No anchors set -- an unanchored wlr-layer-shell surface centers
    // itself on its output, which is exactly the spotlight-style placement
    // wanted here (unlike Bar.qml, which anchors to the top edge).
    implicitWidth: 480
    // 20 (Column margins) + 30 (search row) + 8+1+8 (spacing + separator)
    // fixed budget, then the results list on top of that, capped so a long
    // query can't grow the popup past a sane size.
    implicitHeight: Math.min(67 + resultsColumn.implicitHeight, 420)

    readonly property var results: {
        const q = field.text.trim().toLowerCase();
        if (q.length === 0 || !AppEntries.ready)
            return [];
        return AppEntries.apps.filter(a => a.name.toLowerCase().includes(q)).slice(0, 8);
    }
    property int selectedIndex: 0
    onResultsChanged: root.selectedIndex = 0

    function launchSelected() {
        if (root.results.length === 0)
            return;
        AppEntries.launch(root.results[Math.min(root.selectedIndex, root.results.length - 1)]);
        root.closeRequested();
    }

    Rectangle {
        anchors.fill: parent
        radius: Theme.radiusPanel
        color: Theme.surfaceContainer
        border.width: 1
        border.color: Theme.outlineVariant

        Column {
            anchors.fill: parent
            anchors.margins: 10
            spacing: 8

            Row {
                width: parent.width
                spacing: 8

                Icon {
                    id: searchIcon
                    anchors.verticalCenter: parent.verticalCenter
                    glyph: "search"
                    fallback: "?"
                }

                Item {
                    width: parent.width - searchIcon.width - parent.spacing
                    height: 30
                    anchors.verticalCenter: parent.verticalCenter

                    TextInput {
                        id: field
                        anchors.fill: parent
                        verticalAlignment: TextInput.AlignVCenter
                        color: Theme.surfaceInk
                        font.pixelSize: 14
                        font.family: Theme.uiFontFamily
                        clip: true
                        selectByMouse: true

                        Keys.onEscapePressed: root.closeRequested()
                        Keys.onReturnPressed: root.launchSelected()
                        Keys.onDownPressed: root.selectedIndex = Math.min(root.selectedIndex + 1, Math.max(root.results.length - 1, 0))
                        Keys.onUpPressed: root.selectedIndex = Math.max(root.selectedIndex - 1, 0)
                    }

                    Text {
                        anchors.fill: field
                        verticalAlignment: Text.AlignVCenter
                        visible: field.text.length === 0
                        text: "Anwendung suchen…"
                        color: Theme.outline
                        font.pixelSize: 14
                        font.family: Theme.uiFontFamily
                    }
                }
            }

            Rectangle { width: parent.width; height: 1; color: Theme.outlineVariant; visible: root.results.length > 0 }

            Flickable {
                id: list
                width: parent.width
                height: parent.height - 40
                clip: true
                contentHeight: resultsColumn.implicitHeight
                boundsBehavior: Flickable.StopAtBounds

                Column {
                    id: resultsColumn
                    width: list.width
                    spacing: 2

                    Repeater {
                        model: root.results

                        Rectangle {
                            id: resultRow
                            required property var modelData
                            required property int index
                            width: resultsColumn.width
                            height: 32
                            radius: 8
                            color: resultRow.index === root.selectedIndex ? Theme.primaryContainer : "transparent"

                            Text {
                                anchors.fill: parent
                                anchors.leftMargin: 10
                                anchors.rightMargin: 10
                                verticalAlignment: Text.AlignVCenter
                                text: resultRow.modelData.name
                                color: resultRow.index === root.selectedIndex ? Theme.primaryContainerInk : Theme.surfaceInk
                                font.pixelSize: 12
                                font.family: Theme.uiFontFamily
                                elide: Text.ElideRight
                            }

                            MouseArea {
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onEntered: root.selectedIndex = resultRow.index
                                onClicked: {
                                    AppEntries.launch(resultRow.modelData);
                                    root.closeRequested();
                                }
                            }
                        }
                    }

                    Text {
                        visible: field.text.length > 0 && root.results.length === 0
                        width: resultsColumn.width
                        horizontalAlignment: Text.AlignHCenter
                        topPadding: 8
                        text: "Keine Treffer"
                        color: Theme.outline
                        font.pixelSize: 11
                        font.family: Theme.uiFontFamily
                    }
                }
            }
        }
    }

    Component.onCompleted: field.forceActiveFocus()
}
