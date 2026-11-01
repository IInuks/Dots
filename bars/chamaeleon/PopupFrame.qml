import QtQuick

// Shared flyout chrome: rises from directly under the top bar, roughly
// centered on Popups.anchorX (the trigger's own screen position), clamped
// so it never runs off either screen edge. Always kept loaded (bound via
// `shown`, never destroyed by a Loader) so hiding it mid-animation never
// gets cut short.
Item {
    id: root
    property bool shown: false
    property real screenWidth: 1920
    property real panelWidth: 320
    property real panelHeight: 360
    default property alias content: body.data

    x: Math.max(8, Math.min(root.screenWidth - root.panelWidth - 8, Popups.anchorX - root.panelWidth / 2))
    y: root.shown ? Metrics.barHeight + 6 : Metrics.barHeight - 6
    width: root.panelWidth
    height: root.panelHeight
    visible: opacity > 0.01
    opacity: root.shown ? 1 : 0

    Behavior on opacity { NumberAnimation { duration: Theme.tMed; easing.type: Easing.OutCubic } }
    Behavior on y { NumberAnimation { duration: Theme.tMed; easing.type: Easing.OutCubic } }

    Rectangle {
        anchors.fill: parent
        radius: Theme.rMed
        color: Theme.panel
        border.width: 1
        border.color: Qt.alpha(Theme.text, 0.08)

        Item {
            id: body
            anchors.fill: parent
            anchors.margins: 12
        }
    }

    MouseArea {
        // Swallows clicks so they don't fall through to the backdrop
        // (which closes the popup) when interacting with its contents.
        // z: -1 keeps it behind the Rectangle/body above -- without it,
        // being the last-declared (and thus topmost-stacked) child here
        // put it in front of every MouseArea nested inside `content`
        // (tab buttons, sliders, toggles, ...), swallowing all of them
        // and leaving the whole panel unclickable.
        anchors.fill: parent
        z: -1
        onClicked: {}
    }
}
