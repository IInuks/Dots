import QtQuick
import QtQuick.Layouts
import Quickshell
import "../.."

// Linker Bar-Bereich: mango-Tags 1..N + Titel des aktiven Fensters.
// Uebernommen aus bars/simple/Modules/Bar/Workspaces.qml.
RowLayout {
    id: root

    required property ShellScreen screen
    readonly property string outputName: root.screen ? root.screen.name : ""

    spacing: 10

    function _currentTagIndex() {
        const active = MangoIpc.activeTagsFor(root.outputName);
        if (active.length === 0)
            return 1;
        return Math.min.apply(null, active);
    }

    Item {
        implicitWidth: wsRow.implicitWidth
        implicitHeight: wsRow.implicitHeight

        Row {
            id: wsRow
            spacing: 6

            Repeater {
                model: Settings.workspaceCount

                delegate: Text {
                    id: wsLabel

                    required property int index
                    readonly property int tagIndex: index + 1
                    readonly property var tagData: MangoIpc.tagsFor(root.outputName).find(t => t.index === wsLabel.tagIndex)
                    readonly property bool occupied: tagData ? tagData.client_count > 0 : false
                    readonly property bool active: MangoIpc.activeTagsFor(root.outputName).indexOf(wsLabel.tagIndex) !== -1
                    readonly property bool underlined: wsLabel.active || wsLabel.occupied

                    function _isUnderlined(idx) {
                        if (idx < 1 || idx > Settings.workspaceCount)
                            return false;
                        if (MangoIpc.activeTagsFor(root.outputName).indexOf(idx) !== -1)
                            return true;
                        const data = MangoIpc.tagsFor(root.outputName).find(t => t.index === idx);
                        return data ? data.client_count > 0 : false;
                    }
                    readonly property bool leftNeighborUnderlined: wsLabel._isUnderlined(wsLabel.tagIndex - 1)
                    readonly property bool rightNeighborUnderlined: wsLabel._isUnderlined(wsLabel.tagIndex + 1)

                    text: String(tagIndex)
                    font.family: Colors.fontFamily
                    font.pointSize: Colors.fontSize
                    font.letterSpacing: Colors.letterSpacing
                    color: active || occupied ? Colors.text : Colors.textDim

                    Rectangle {
                        visible: wsLabel.underlined
                        anchors.top: parent.bottom
                        anchors.topMargin: 2
                        anchors.left: parent.left
                        anchors.leftMargin: wsLabel.leftNeighborUnderlined ? -wsRow.spacing / 2 : 0
                        anchors.right: parent.right
                        anchors.rightMargin: wsLabel.rightNeighborUnderlined ? -wsRow.spacing / 2 : 0
                        height: 2
                        color: wsLabel.active ? Colors.accentAlt : Colors.accent
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: MangoIpc.viewTag(root.outputName, wsLabel.tagIndex)
                    }
                }
            }
        }

        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.NoButton
            onWheel: event => {
                const current = root._currentTagIndex();
                const count = Settings.workspaceCount;
                const next = event.angleDelta.y > 0 ? (current - 2 + count) % count + 1 : current % count + 1;
                MangoIpc.viewTag(root.outputName, next);
            }
        }
    }

    Text {
        id: titleLabel

        readonly property var monitor: MangoIpc.monitorFor(root.outputName)
        readonly property string rawTitle: monitor && monitor.active_client ? monitor.active_client.title : ""
        readonly property string displayTitle: rawTitle.length > 0 ? rawTitle : "Desktop"

        text: displayTitle.length > Settings.windowTitleMaxLength ? displayTitle.substring(0, Settings.windowTitleMaxLength - 1) + "…" : displayTitle
        font.family: Colors.fontFamily
        font.pointSize: Colors.fontSize
        font.letterSpacing: Colors.letterSpacing
        color: Colors.textDim
        elide: Text.ElideRight
    }
}
