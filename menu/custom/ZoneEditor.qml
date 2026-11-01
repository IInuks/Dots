import QtQuick
import ".."
import "../custombarlib" as Cbl

// One zone's module list (left/center/right), talking to
// CustomBarsStore.configFile.adapter directly -- self-contained, BarEditor
// just instantiates three of these.
Column {
    id: root

    required property string zoneKey
    required property string label

    property int expandedIndex: -1
    property bool paletteOpen: false

    readonly property var items: (CustomBarsStore.configFile.adapter.zones && CustomBarsStore.configFile.adapter.zones[zoneKey]) || []

    Cbl.ModuleRegistry { id: registry }

    function _setItems(items) {
        const z = Object.assign({}, CustomBarsStore.configFile.adapter.zones);
        z[zoneKey] = items;
        CustomBarsStore.configFile.adapter.zones = z;
    }
    function addModule(type) {
        const items = root.items.slice();
        items.push({ type: type, settings: registry.defaultsFor(type) });
        root._setItems(items);
        root.paletteOpen = false;
    }
    function removeModule(index) {
        const items = root.items.slice();
        items.splice(index, 1);
        root._setItems(items);
        if (root.expandedIndex === index) root.expandedIndex = -1;
    }
    function moveModule(index, dir) {
        const items = root.items.slice();
        const j = index + dir;
        if (j < 0 || j >= items.length) return;
        const tmp = items[index]; items[index] = items[j]; items[j] = tmp;
        root._setItems(items);
    }
    function updateSettings(index, key, value) {
        const items = root.items.slice();
        items[index] = { type: items[index].type, settings: Object.assign({}, items[index].settings, { [key]: value }) };
        root._setItems(items);
    }

    width: parent ? parent.width : 380
    spacing: 6

    Text {
        text: root.label
        color: Qt.rgba(Theme.foreground.r, Theme.foreground.g, Theme.foreground.b, 0.6)
        font.pixelSize: 11
        font.bold: true
    }

    Flow {
        width: root.width
        spacing: 6

        Repeater {
            model: root.items
            delegate: ModuleChip {
                id: chip
                required property var modelData
                required property int index
                moduleType: modelData.type
                canMoveUp: index > 0
                canMoveDown: index < root.items.length - 1
                expanded: root.expandedIndex === index
                onMoveUp: root.moveModule(index, -1)
                onMoveDown: root.moveModule(index, 1)
                onRemoved: root.removeModule(index)
                onToggled: root.expandedIndex = root.expandedIndex === index ? -1 : index
            }
        }
    }

    ModuleSettingsForm {
        width: root.width
        visible: root.expandedIndex >= 0 && root.expandedIndex < root.items.length
        moduleType: (root.expandedIndex >= 0 && root.expandedIndex < root.items.length) ? root.items[root.expandedIndex].type : ""
        settings: (root.expandedIndex >= 0 && root.expandedIndex < root.items.length) ? root.items[root.expandedIndex].settings : ({})
        onChanged: (key, value) => root.updateSettings(root.expandedIndex, key, value)
    }

    Text {
        text: root.paletteOpen ? "− Modul" : "+ Modul"
        color: Theme.accent
        font.pixelSize: 11
        MouseArea {
            anchors.fill: parent
            anchors.margins: -4
            cursorShape: Qt.PointingHandCursor
            onClicked: root.paletteOpen = !root.paletteOpen
        }
    }

    ModulePalette {
        width: root.width
        visible: root.paletteOpen
        onPicked: type => root.addModule(type)
    }
}
