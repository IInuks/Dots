import QtQuick
import Quickshell
import Quickshell.Widgets

Column {
    id: root
    property var results: []
    property string query: ""
    property int selectedIndex: 0
    spacing: 2

    function _highlight(name) {
        const idx = name.toLowerCase().indexOf(root.query.toLowerCase());
        if (idx < 0 || root.query.length === 0) return name;
        const pre = name.slice(0, idx);
        const hit = name.slice(idx, idx + root.query.length);
        const post = name.slice(idx + root.query.length);
        return pre + "<font color=\"" + Theme.accent + "\">" + hit + "</font>" + post;
    }

    Repeater {
        model: root.results
        delegate: Rectangle {
            id: row
            required property var modelData
            required property int index
            width: root.width
            height: 30
            radius: Theme.radiusSmall
            color: index === root.selectedIndex ? Theme.surfaceAlt : "transparent"

            Row {
                anchors.left: parent.left
                anchors.leftMargin: 8
                anchors.right: parent.right
                anchors.rightMargin: 8
                anchors.verticalCenter: parent.verticalCenter
                spacing: 8

                IconImage {
                    anchors.verticalCenter: parent.verticalCenter
                    implicitSize: 16
                    source: Quickshell.hasThemeIcon(row.modelData.icon) ? Quickshell.iconPath(row.modelData.icon) : ""
                    visible: source !== ""
                }
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    textFormat: Text.StyledText
                    text: root._highlight(row.modelData.name)
                    color: Theme.text
                    font.pixelSize: 13
                    elide: Text.ElideRight
                    width: parent.width - 24
                }
            }

            MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onEntered: root.selectedIndex = row.index
                onClicked: {
                    DesktopEntries.launch(row.modelData);
                    MenuState.close();
                }
            }
        }
    }
}
