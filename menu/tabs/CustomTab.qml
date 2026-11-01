import QtQuick
import ".."
import "../custom"

// Body of the "Eigene Bars" wizard step (steps/CustomStep.qml draws the
// heading): overview of saved custom bars (grid of cards + "+ Neu"), or -- while CustomBarsStore.editingSlug is set -- the editor for one of
// them. Every bar created here becomes a real bars/custom-<slug>/ folder,
// so it also just shows up in the list of the "Bar" step.
Item {
    id: tab
    focus: true

    readonly property int columns: Math.max(1, Math.floor(tab.width / (168 + 10)))

    Loader {
        anchors.fill: parent
        sourceComponent: CustomBarsStore.editingSlug.length ? editorComp : overviewComp
    }

    Component {
        id: overviewComp

        Column {
            spacing: 12
            width: tab.width

            Grid {
                id: grid
                width: parent.width
                columns: tab.columns
                spacing: 10

                Repeater {
                    model: CustomBarsStore.list
                    delegate: CustomBarCard {
                        required property var modelData
                        slug: modelData.slug
                        barName: modelData.name
                        onEditRequested: CustomBarsStore.edit(modelData.slug)
                        onDeleteRequested: CustomBarsStore.remove(modelData.slug)
                    }
                }

                Rectangle {
                    width: 168
                    height: 110
                    radius: 12
                    color: Qt.rgba(1, 1, 1, 0.04)
                    border.width: 1
                    border.color: Qt.rgba(Theme.foreground.r, Theme.foreground.g, Theme.foreground.b, 0.25)

                    Text {
                        anchors.centerIn: parent
                        text: "+ Neu"
                        font.pixelSize: 14
                        color: Theme.accent
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: CustomBarsStore.edit(CustomBarsStore.newSlug())
                    }
                }
            }
        }
    }

    Component {
        id: editorComp
        BarEditor { width: tab.width; height: tab.height }
    }
}
