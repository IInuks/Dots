import QtQuick

Item {
    id: root
    implicitHeight: 26
    implicitWidth: box.width

    readonly property bool active: MenuState.openMenu === "launcher"
    readonly property string query: field.text

    readonly property var results: {
        if (root.query.length === 0 || !DesktopEntries.ready) return [];
        const q = root.query.toLowerCase();
        return DesktopEntries.apps.filter(a => a.name.toLowerCase().includes(q)).slice(0, 6);
    }

    property int selectedIndex: 0
    onResultsChanged: root.selectedIndex = 0

    onActiveChanged: {
        if (active) field.forceActiveFocus();
        else { field.text = ""; field.focus = false; }
    }

    function launchSelected() {
        if (root.results.length === 0) return;
        const app = root.results[Math.min(root.selectedIndex, root.results.length - 1)];
        DesktopEntries.launch(app);
        MenuState.close();
    }

    Rectangle {
        id: box
        height: parent.height
        width: 200
        radius: height / 2
        color: Theme.surfaceAlt
        opacity: root.active ? 1 : 0.7
        Behavior on opacity { NumberAnimation { duration: Theme.animFast } }

        Icon {
            id: icon
            anchors.left: parent.left
            anchors.leftMargin: 6
            anchors.verticalCenter: parent.verticalCenter
            name: "search"
            size: 14
            tint: Theme.textDim
        }

        TextInput {
            id: field
            anchors.left: icon.right
            anchors.right: parent.right
            anchors.leftMargin: 6
            anchors.rightMargin: 10
            anchors.verticalCenter: parent.verticalCenter
            color: Theme.text
            font.pixelSize: 12
            clip: true
            selectByMouse: true

            Keys.onEscapePressed: MenuState.close()
            Keys.onReturnPressed: root.launchSelected()
            Keys.onDownPressed: root.selectedIndex = Math.min(root.selectedIndex + 1, Math.max(root.results.length - 1, 0))
            Keys.onUpPressed: root.selectedIndex = Math.max(root.selectedIndex - 1, 0)
        }

        Text {
            anchors.left: icon.right
            anchors.right: parent.right
            anchors.leftMargin: 6
            anchors.rightMargin: 10
            anchors.verticalCenter: parent.verticalCenter
            visible: !root.active && field.text.length === 0
            text: "Suchen…"
            color: Theme.textDim
            font.pixelSize: 12
            elide: Text.ElideRight
        }

        MouseArea {
            anchors.fill: parent
            visible: !root.active
            cursorShape: Qt.PointingHandCursor
            onClicked: MenuState.toggle("launcher")
        }
    }
}
