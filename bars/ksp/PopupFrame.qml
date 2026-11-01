import QtQuick

// Shared KSP-styled flyout chrome: rises from directly under the top bar,
// centered on Popups.anchorX (the trigger's own screen position), clamped
// to the screen edges. Always kept loaded (bound via `shown`, never
// destroyed by a Loader) so hiding it mid-animation never gets cut short
// -- same contract as bars/chamaeleon/PopupFrame.qml.
//
// Distinct look: hazard-stripe header bar with an all-caps title, HUD
// corner brackets, and a scanline that sweeps top-to-bottom once on open
// (like a console booting up its display).
Item {
    id: root
    property bool shown: false
    property real screenWidth: 1920
    property real panelWidth: 320
    property real panelHeight: 360
    property string title: "PANEL"
    default property alias content: body.data

    readonly property int _headerHeight: 30

    x: Math.max(8, Math.min(root.screenWidth - root.panelWidth - 8, Popups.anchorX - root.panelWidth / 2))
    y: root.shown ? Metrics.barHeight + 6 : Metrics.barHeight - 10
    width: root.panelWidth
    height: root.panelHeight
    visible: opacity > 0.01
    opacity: root.shown ? 1 : 0
    scale: root.shown ? 1 : 0.97
    transformOrigin: Item.Top

    Behavior on opacity { NumberAnimation { duration: Theme.tMed; easing.type: Easing.OutCubic } }
    Behavior on y { NumberAnimation { duration: Theme.tMed; easing.type: Easing.OutCubic } }
    Behavior on scale { NumberAnimation { duration: Theme.tMed; easing.type: Easing.OutBack } }

    onShownChanged: if (shown) scanline.restart()

    Rectangle {
        id: frame
        anchors.fill: parent
        radius: Theme.rMed
        color: Theme.panel
        border.width: 1
        border.color: Qt.alpha(Theme.accent, 0.35)
        clip: true

        Rectangle {
            id: header
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            height: root._headerHeight
            color: Theme.panelBright

            HazardStripe {
                anchors.bottom: parent.bottom
                anchors.left: parent.left
                anchors.right: parent.right
                height: 3
                stripeColor: Theme.accent
            }

            Text {
                anchors.left: parent.left
                anchors.leftMargin: 12
                anchors.verticalCenter: parent.verticalCenter
                anchors.verticalCenterOffset: -1
                text: root.title
                color: Theme.text
                font.family: Metrics.fontFamily
                font.pixelSize: 11
                font.bold: true
                font.letterSpacing: 2
                font.capitalization: Font.AllUppercase
            }

            Row {
                anchors.right: parent.right
                anchors.rightMargin: 10
                anchors.verticalCenter: parent.verticalCenter
                anchors.verticalCenterOffset: -1
                spacing: 4
                Repeater {
                    model: 3
                    delegate: Rectangle {
                        width: 4; height: 4; radius: 2
                        color: Qt.alpha(Theme.accent, 0.6)
                    }
                }
            }
        }

        Item {
            id: body
            anchors.top: header.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.margins: 12
        }

        Rectangle {
            id: scanline
            width: parent.width
            height: 2
            color: Qt.alpha(Theme.accent, 0.8)
            y: header.height
            visible: opacity > 0.01
            opacity: 0

            function restart() { scanAnim.restart(); }

            SequentialAnimation {
                id: scanAnim
                ScriptAction { script: { scanline.y = header.height; scanline.opacity = 0.9; } }
                NumberAnimation { target: scanline; property: "y"; to: frame.height; duration: 420; easing.type: Easing.OutCubic }
                NumberAnimation { target: scanline; property: "opacity"; to: 0; duration: 120 }
            }
        }

        CrtOverlay { anchors.fill: parent }
    }

    CornerBrackets {
        anchors.fill: parent
        inset: -3
        armLength: 10
        strokeWidth: 1.5
    }

    MouseArea {
        // Swallows clicks so they don't fall through to the backdrop
        // (which closes the popup) when interacting with its contents.
        // z: -1 keeps it behind everything above -- without it, being the
        // last-declared child here would put it in front of every
        // MouseArea nested inside `content`, swallowing all of them.
        anchors.fill: parent
        z: -1
        onClicked: {}
    }
}
