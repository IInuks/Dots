import QtQuick
import ".."

// Editor for one custom bar. Reads/writes CustomBarsStore.configFile.adapter
// directly (see that file's comment) -- no separate draft copy to keep in
// sync, every control here is a thin binding onto the adapter.
Flickable {
    id: root

    readonly property var adapter: CustomBarsStore.configFile.adapter
    readonly property bool ready: CustomBarsStore.loaded

    property bool confirmingDelete: false

    contentWidth: width
    contentHeight: content.implicitHeight
    clip: true
    boundsBehavior: Flickable.StopAtBounds

    Column {
        id: content
        width: root.width
        spacing: 14
        visible: root.ready

        // -- Header ----------------------------------------------------
        Row {
            width: parent.width
            spacing: 8

            Text {
                text: "←"
                font.pixelSize: 16
                color: Theme.foreground
                anchors.verticalCenter: parent.verticalCenter
                MouseArea {
                    anchors.fill: parent
                    anchors.margins: -6
                    cursorShape: Qt.PointingHandCursor
                    onClicked: CustomBarsStore.closeEditor()
                }
            }

            TextField {
                width: parent.width - 130
                anchors.verticalCenter: parent.verticalCenter
                text: root.adapter.name || ""
                placeholder: "Name der Bar"
                onEditingFinished: root.adapter.name = text
            }

            Rectangle {
                width: 64
                height: 28
                radius: 8
                anchors.verticalCenter: parent.verticalCenter
                color: CustomBarsStore.saving ? Qt.rgba(1, 1, 1, 0.08) : Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.3)
                border.width: 1
                border.color: Theme.accent

                Text {
                    anchors.centerIn: parent
                    text: CustomBarsStore.saving ? "…" : "Speichern"
                    font.pixelSize: 11
                    color: Theme.foreground
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: CustomBarsStore.save()
                }
            }
        }

        Text {
            visible: CustomBarsStore.lastError.length > 0
            text: CustomBarsStore.lastError
            color: "#ff8080"
            font.pixelSize: 10
            width: parent.width
            wrapMode: Text.Wrap
        }

        // -- Stil / Position --------------------------------------------
        Row {
            width: parent.width
            spacing: 20

            Row {
                spacing: 6
                Repeater {
                    model: [{ key: "bar", label: "Leiste" }, { key: "islands", label: "Inseln" }]
                    delegate: Rectangle {
                        id: styleBtn
                        required property var modelData
                        readonly property bool active: root.adapter.style === modelData.key
                        width: styleLabel.implicitWidth + 16
                        height: 24
                        radius: 12
                        color: active ? Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.3) : Qt.rgba(1, 1, 1, 0.06)
                        border.width: active ? 1 : 0
                        border.color: Theme.accent

                        Text { id: styleLabel; anchors.centerIn: parent; text: styleBtn.modelData.label; font.pixelSize: 11; color: Theme.foreground }
                        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: root.adapter.style = styleBtn.modelData.key }
                    }
                }
            }

            Row {
                spacing: 6
                Repeater {
                    model: [{ key: "top", label: "Oben" }, { key: "bottom", label: "Unten" }]
                    delegate: Rectangle {
                        id: posBtn
                        required property var modelData
                        readonly property bool active: root.adapter.position === modelData.key
                        width: posLabel.implicitWidth + 16
                        height: 24
                        radius: 12
                        color: active ? Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.3) : Qt.rgba(1, 1, 1, 0.06)
                        border.width: active ? 1 : 0
                        border.color: Theme.accent

                        Text { id: posLabel; anchors.centerIn: parent; text: posBtn.modelData.label; font.pixelSize: 11; color: Theme.foreground }
                        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: root.adapter.position = posBtn.modelData.key }
                    }
                }
            }
        }

        // -- Vorschau -----------------------------------------------------
        BarPreview { width: parent.width }

        // -- Form/Größe pro Insel (nur Stil "Inseln") -- Position wird nicht
        // hier, sondern per Drag direkt in BarPreview eingestellt. ----------
        Column {
            width: parent.width
            spacing: 14
            visible: root.adapter.style === "islands"

            IslandStyleEditor { zoneKey: "left"; label: "Insel links"; width: parent.width }
            IslandStyleEditor { zoneKey: "center"; label: "Insel mitte"; width: parent.width }
            IslandStyleEditor { zoneKey: "right"; label: "Insel rechts"; width: parent.width }
        }

        // -- Module pro Zone ----------------------------------------------
        ZoneEditor { zoneKey: "left"; label: "Links"; width: parent.width }
        ZoneEditor { zoneKey: "center"; label: "Mitte"; width: parent.width }
        ZoneEditor { zoneKey: "right"; label: "Rechts"; width: parent.width }

        // -- Theme ----------------------------------------------------------
        ThemeEditor {
            width: parent.width
            theme: root.adapter.theme || {}
            onChanged: (key, value) => {
                const t = Object.assign({}, root.adapter.theme);
                t[key] = value;
                root.adapter.theme = t;
            }
        }

        // -- Löschen --------------------------------------------------------
        Row {
            width: parent.width
            spacing: 10

            Text {
                text: root.confirmingDelete ? "Wirklich löschen?" : "Bar löschen"
                font.pixelSize: 11
                color: root.confirmingDelete ? "#ff8080" : Qt.rgba(Theme.foreground.r, Theme.foreground.g, Theme.foreground.b, 0.5)
                MouseArea {
                    anchors.fill: parent
                    anchors.margins: -4
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (root.confirmingDelete) {
                            CustomBarsStore.remove(CustomBarsStore.editingSlug);
                        } else {
                            root.confirmingDelete = true;
                        }
                    }
                }
            }

            Text {
                visible: root.confirmingDelete
                text: "Abbrechen"
                font.pixelSize: 11
                color: Theme.accent
                MouseArea {
                    anchors.fill: parent
                    anchors.margins: -4
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.confirmingDelete = false
                }
            }
        }

        Item { width: 1; height: 6 }
    }
}
