import QtQuick
import "../../"

// Small static 3-pip preview of one Bar/lyrics/WorkspacePips.qml style
// (empty/active/occupied mock tags), used by SettingsDropdown.qml's picker
// so the user sees the actual look before picking it, not just a name.
// Geometry mirrors WorkspacePips.qml's own dot sizing per style exactly,
// just fed mock data instead of MangoState.tags.
Row {
    id: root
    property string previewStyle: "dots"
    spacing: 6
    readonly property int _size: 14

    readonly property var _mock: [
        { active: false, occupied: false },
        { active: true, occupied: true },
        { active: false, occupied: true }
    ]
    readonly property var _romanLabels: ["I", "II", "III"]

    Repeater {
        model: root._mock

        Item {
            id: cell
            required property var modelData
            required property int index

            readonly property bool isBars: root.previewStyle === "bars"
            readonly property bool showsText: root.previewStyle === "numbers" || root.previewStyle === "roman"

            width: root._size
            height: root._size * 1.4

            Rectangle {
                id: dot
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.verticalCenter: cell.isBars ? undefined : parent.verticalCenter
                anchors.bottom: cell.isBars ? parent.bottom : undefined
                radius: cell.isBars ? 2 : width / 2
                width: {
                    if (cell.isBars)
                        return root._size * 0.5;
                    if (cell.showsText)
                        return root._size;
                    return cell.modelData.active ? root._size : (cell.modelData.occupied ? root._size * 0.6 : root._size * 0.4);
                }
                height: cell.isBars ? (cell.modelData.active ? root._size * 1.3 : (cell.modelData.occupied ? root._size * 0.8 : root._size * 0.45)) : width
                color: cell.modelData.active ? Colors.primary : (cell.modelData.occupied ? Colors.tertiary : "transparent")
                border.width: (cell.modelData.active || cell.modelData.occupied) ? 0 : 1.5
                border.color: Qt.rgba(Colors.outline.r, Colors.outline.g, Colors.outline.b, 0.6)

                Text {
                    anchors.centerIn: parent
                    visible: !cell.isBars && (cell.showsText || cell.modelData.active)
                    text: root.previewStyle === "roman" ? root._romanLabels[cell.index] : String(cell.index + 1)
                    font.family: Style.textFont
                    font.pixelSize: 9
                    font.weight: Font.Bold
                    color: !cell.showsText ? Colors.primaryText : (cell.modelData.active ? Colors.primaryText : (cell.modelData.occupied ? Colors.surface : Colors.backgroundText))
                }
            }
        }
    }
}
