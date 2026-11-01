import QtQuick
import "../../"

// New settings dropdown, opened via Bar/widgets/SettingsWidget.qml. So far
// just the one control the user asked for: which idle-state look the
// middle island's workspace indicator uses (Config.workspaceStyle, read by
// Bar/lyrics/WorkspacePips.qml). Each option shows a live 3-pip preview
// (WorkspaceStylePreview.qml) instead of just a name, since "Punkte" vs.
// "Balken" means nothing without seeing it.
Column {
    id: root
    width: Style.dropdownMinWidth - 24
    spacing: 10

    readonly property var _styles: [
        { id: "dots", label: "Punkte" },
        { id: "numbers", label: "Zahlen" },
        { id: "roman", label: "Römisch" },
        { id: "bars", label: "Balken" }
    ]

    readonly property var _launcherModes: [
        { id: "slice", label: "Slice" },
        { id: "hex", label: "Hex" },
        { id: "grid", label: "Grid" }
    ]

    Text {
        text: "WORKSPACE-STIL"
        font.family: Style.textFont
        font.pixelSize: Style.fontSubtitle
        font.weight: Font.DemiBold
        color: Colors.primary
    }

    Repeater {
        model: root._styles

        Item {
            id: row
            required property var modelData
            readonly property bool selected: Config.workspaceStyle === row.modelData.id

            width: root.width
            height: 30

            Rectangle {
                anchors.fill: parent
                anchors.margins: -4
                radius: Style.radius8
                color: row.selected ? Qt.rgba(Colors.primary.r, Colors.primary.g, Colors.primary.b, 0.14) : "transparent"
                Behavior on color { ColorAnimation { duration: Style.anim150 } }
            }

            Row {
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                spacing: 12

                WorkspaceStylePreview {
                    anchors.verticalCenter: parent.verticalCenter
                    previewStyle: row.modelData.id
                }

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: row.modelData.label
                    font.family: Style.textFont
                    font.pixelSize: 12
                    font.weight: row.selected ? Font.DemiBold : Font.Medium
                    color: row.selected ? Colors.primary : Colors.backgroundText
                }
            }

            Text {
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                visible: row.selected
                text: "✓"
                font.family: Style.textFont
                font.pixelSize: 13
                font.weight: Font.Bold
                color: Colors.primary
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: Config.setWorkspaceStyle(row.modelData.id)
            }
        }
    }

    Text {
        text: "LAUNCHER-ANSICHT"
        font.family: Style.textFont
        font.pixelSize: Style.fontSubtitle
        font.weight: Font.DemiBold
        color: Colors.primary
    }

    Repeater {
        model: root._launcherModes

        Item {
            id: modeRow
            required property var modelData
            readonly property bool selected: Config.launcherDisplayMode === modeRow.modelData.id

            width: root.width
            height: 30

            Rectangle {
                anchors.fill: parent
                anchors.margins: -4
                radius: Style.radius8
                color: modeRow.selected ? Qt.rgba(Colors.primary.r, Colors.primary.g, Colors.primary.b, 0.14) : "transparent"
                Behavior on color { ColorAnimation { duration: Style.anim150 } }
            }

            Text {
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                text: modeRow.modelData.label
                font.family: Style.textFont
                font.pixelSize: 12
                font.weight: modeRow.selected ? Font.DemiBold : Font.Medium
                color: modeRow.selected ? Colors.primary : Colors.backgroundText
            }

            Text {
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                visible: modeRow.selected
                text: "✓"
                font.family: Style.textFont
                font.pixelSize: 13
                font.weight: Font.Bold
                color: Colors.primary
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: Config.setLauncherDisplayMode(modeRow.modelData.id)
            }
        }
    }
}
