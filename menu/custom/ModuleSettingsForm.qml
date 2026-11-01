import QtQuick
import ".."
import "../custombarlib" as Cbl

// Settings form for one module instance, generated from
// ModuleRegistry's settingsFields (v1 only has "choice" fields -- a row of
// pill buttons per field, current value highlighted).
Column {
    id: root

    property string moduleType: ""
    property var settings: ({})

    signal changed(string key, var value)

    Cbl.ModuleRegistry { id: registry }
    readonly property var meta: registry.byType(moduleType)

    width: parent ? parent.width : 160
    spacing: 6
    visible: meta && meta.settingsFields.length > 0

    Repeater {
        model: root.meta ? root.meta.settingsFields : []
        delegate: Column {
            id: fieldCol
            required property var modelData
            width: root.width
            spacing: 3

            Text {
                text: fieldCol.modelData.label
                color: Qt.rgba(Theme.foreground.r, Theme.foreground.g, Theme.foreground.b, 0.6)
                font.pixelSize: 10
            }

            Flow {
                width: fieldCol.width
                spacing: 4

                Repeater {
                    model: fieldCol.modelData.options
                    delegate: Rectangle {
                        id: opt
                        required property var modelData
                        readonly property bool active: root.settings[fieldCol.modelData.key] === modelData
                        width: label.implicitWidth + 14
                        height: 22
                        radius: 11
                        color: active ? Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.3) : Qt.rgba(1, 1, 1, 0.06)
                        border.width: active ? 1 : 0
                        border.color: Theme.accent

                        Text {
                            id: label
                            anchors.centerIn: parent
                            text: String(opt.modelData)
                            font.pixelSize: 10
                            color: Theme.foreground
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.changed(fieldCol.modelData.key, opt.modelData)
                        }
                    }
                }
            }
        }
    }
}
