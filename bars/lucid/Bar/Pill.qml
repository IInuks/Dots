import QtQuick
import "../"

// Shared morph shell for every bar module: a fully-rounded pill at rest that
// grows into a rounded panel when opened, the trigger icon staying pixel-
// fixed at its anchor corner throughout. Adapted from the already-proven
// bars/blobs/components/MorphBlob.qml (same author's own prior work in this
// repo, not Lucid's) -- same width/height/radius Behavior morph, same
// delayed body-fade-in so content doesn't reflow mid-grow, same
// iconAnchor scheme. Owner (Bar.qml) decides `open`/exclusivity; this
// component only knows how to morph and reports `clicked`.
Item {
    id: root

    required property string moduleId
    // Which corner of the panel stays under the fixed trigger icon while
    // the opposite edge/edges grow away from it.
    property string iconAnchor: "center" // "left" | "center" | "right"

    property real restWidth: Math.max(iconHolder.contentWidth + 24, root.restHeight)
    property real restHeight: Theme.pillHeight
    property real openWidth: root.restWidth
    property real openHeight: root.restHeight
    property bool open: false

    signal clicked

    default property alias headerData: iconHolder.data
    property alias bodyData: bodyContainer.data

    width: root.open ? root.openWidth : root.restWidth
    height: root.open ? root.openHeight : root.restHeight

    Behavior on width {
        SpringAnimation { spring: Theme.morphSpring; damping: Theme.morphDamping }
    }
    Behavior on height {
        SpringAnimation { spring: Theme.morphSpring; damping: Theme.morphDamping }
    }

    Rectangle {
        id: surface
        anchors.fill: parent
        color: Theme.surfaceContainer
        border.color: Theme.outlineVariant
        border.width: 1
        clip: true

        radius: root.open ? Theme.radiusPanel : root.restHeight / 2
        Behavior on radius {
            NumberAnimation { duration: Theme.durSlow; easing.type: Theme.easeOut }
        }

        // Fixed rest-sized area for the trigger icon, pinned to iconAnchor
        // so it never moves as the surface grows around/away from it.
        Item {
            id: iconHolder
            // Item never auto-sizes to its children the way Row/Column do,
            // so `implicitWidth` here would silently stay 0 forever --
            // every pill's restWidth collapsed to plain restHeight (40px)
            // regardless of header content, invisible for a lone Icon
            // (~20px, fits inside 40 by luck) but clipping wider headers
            // like Clock's/Tags' icon+text Row (~55-60px). Read the actual
            // header content's own implicitWidth instead -- it's intrinsic
            // to that item (computed from its own children/text), not
            // dependent on iconHolder's width, so this can't loop back
            // through the anchors.centerIn/left/right states below the way
            // binding to childrenRect.width would.
            readonly property real contentWidth: iconHolder.children.length > 0 ? iconHolder.children[0].implicitWidth : 0
            width: Math.max(iconHolder.contentWidth, root.restHeight)
            height: root.restHeight
            anchors.top: parent.top

            states: [
                State {
                    name: "left"
                    AnchorChanges { target: iconHolder; anchors.left: surface.left }
                },
                State {
                    name: "center"
                    AnchorChanges { target: iconHolder; anchors.horizontalCenter: surface.horizontalCenter }
                },
                State {
                    name: "right"
                    AnchorChanges { target: iconHolder; anchors.right: surface.right }
                }
            ]
            state: root.iconAnchor
        }

        MouseArea {
            anchors.fill: iconHolder
            onClicked: root.clicked()
        }

        Item {
            id: bodyContainer
            anchors.top: iconHolder.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            opacity: 0
        }
    }

    onOpenChanged: {
        if (root.open) {
            bodyFadeIn.start();
        } else {
            bodyFadeIn.stop();
            bodyContainer.opacity = 0;
        }
    }

    SequentialAnimation {
        id: bodyFadeIn
        PauseAnimation { duration: Theme.durBase }
        NumberAnimation {
            target: bodyContainer
            property: "opacity"
            to: 1
            duration: Theme.durBase
            easing.type: Theme.easeOut
        }
    }
}
