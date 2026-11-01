import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import "../../"
import "../../components"
import "../../services"

ColumnLayout {
    id: page
    spacing: Theme.tileGap

    property var monitors: []

    Process {
        running: true
        command: ["mmsg", "get", "all-monitors"]
        stdout: StdioCollector {
            onStreamFinished: {
                try { page.monitors = JSON.parse(text).monitors ?? []; } catch (e) {}
            }
        }
    }

    Tile {
        order: 1
        Layout.fillWidth: true
        Layout.preferredHeight: 92
        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 14
            spacing: 8
            RowLayout {
                Layout.fillWidth: true
                Icon { name: "light_mode"; size: Theme.iconItem }
                Txt { text: "Brightness"; font.weight: Font.DemiBold; Layout.fillWidth: true }
                Txt { text: Brightness.available ? Math.round(Brightness.value * 100) + "%" : ""; color: Theme.textDim }
            }
            Slider {
                Layout.fillWidth: true
                visible: Brightness.available
                value: Brightness.value
                onMoved: v => Brightness.set(v)
            }
            Txt {
                visible: !Brightness.available
                Layout.fillWidth: true
                text: "No backlight found. Install ddcutil to control external monitors over DDC/CI."
                color: Theme.textDim
                font.pixelSize: Theme.fontSmall
                wrapMode: Text.Wrap
            }
        }
    }

    Repeater {
        model: page.monitors
        Tile {
            order: 2
            required property var modelData
            Layout.fillWidth: true
            Layout.preferredHeight: 64
            RowLayout {
                anchors.fill: parent
                anchors.margins: 14
                spacing: 12
                Icon { name: "desktop_windows"; size: 22; color: Theme.accent }
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 0
                    Txt { text: modelData.name; font.weight: Font.DemiBold }
                    Txt {
                        text: modelData.width + "×" + modelData.height + " · scale " + modelData.scale + " · layout " + modelData.layout_symbol
                        color: Theme.textDim
                        font.pixelSize: Theme.fontSmall
                    }
                }
            }
        }
    }

    Item { Layout.fillHeight: true }
}
