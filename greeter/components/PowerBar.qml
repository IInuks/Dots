import QtQuick
import ".."

// Style menu, suspend, reboot and power off as round glass buttons.
Row {
    id: root

    property var ctl: null
    property int size: 44
    property bool showStyle: true
    property bool labelBelow: false
    spacing: Theme.spacingM

    IconButton { labelBelow: root.labelBelow; visible: root.showStyle; size: root.size; glyph: "󰏘"; label: "Style"; onClicked: root.ctl.openStyles() }
    IconButton { labelBelow: root.labelBelow; size: root.size; glyph: "󰤄"; label: "Suspend"; onClicked: root.ctl.power("suspend") }
    IconButton { labelBelow: root.labelBelow; size: root.size; glyph: "󰜉"; label: "Reboot"; onClicked: root.ctl.power("reboot") }
    IconButton { labelBelow: root.labelBelow; size: root.size; glyph: "󰐥"; label: "Power off"; tint: Theme.danger; onClicked: root.ctl.power("poweroff") }
}
