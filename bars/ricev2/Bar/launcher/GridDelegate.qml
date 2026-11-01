import QtQuick
import Quickshell
import Quickshell.Widgets
import "../../"

// Menus-prompt section 2, "Alternative Modi" -> "grid": plain rounded
// tiles, per spec's own numbers ("6 x 3 Kacheln a 300x169px, Radius 6,
// Abstand 8, Farbe surfaceContainer @ 0.85. Bei Hover 2px Rand in primary,
// Abdunkelung 0.4 -> 0.15. Name 10px Bold weiß"). The spec doesn't mention
// a keyboard-selected state distinct from hover -- filled in the same way
// SliceDelegate/HexDelegate treat "selected" (full brightness, thicker
// border) so arrow-key navigation stays visible without a mouse, a
// judgment call rather than a guess (see README "Noch nicht gebaut").
// Sized/clipped with a plain Rectangle -- no Canvas mask needed like the
// skewed slice/hex shapes, a rounded rect clips natively.
Item {
    id: root

    required property var modelData
    required property int index
    required property int selectedIndex

    readonly property bool selected: root.index === root.selectedIndex
    readonly property bool _hovered: mouseArea.containsMouse

    signal selectRequested
    signal activated

    width: Style.gridTileWidth
    height: Style.gridTileHeight

    Rectangle {
        id: tile
        anchors.fill: parent
        radius: Style.gridTileRadius
        clip: true
        color: Qt.rgba(Colors.surfaceContainer.r, Colors.surfaceContainer.g, Colors.surfaceContainer.b, 0.85)
        border.width: root.selected ? 3 : (root._hovered ? 2 : 0)
        border.color: root.selected ? Colors.primary : Qt.rgba(Colors.primary.r, Colors.primary.g, Colors.primary.b, 0.8)
        Behavior on border.width { NumberAnimation { duration: Style.animVeryFast } }

        readonly property string _artwork: AppIndex.artworkPath(root.modelData)

        Image {
            id: bgImage
            anchors.fill: parent
            source: tile._artwork
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
            visible: tile._artwork !== "" && status === Image.Ready
        }

        IconImage {
            id: iconImg
            anchors.centerIn: parent
            implicitSize: 64
            visible: !bgImage.visible && status === Image.Ready
            source: root.modelData.icon !== "" ? Quickshell.iconPath(root.modelData.icon, "application-x-executable") : ""
        }

        Text {
            anchors.centerIn: parent
            visible: !bgImage.visible && !iconImg.visible
            text: (root.modelData.name || "?").trim().charAt(0).toUpperCase()
            font.family: Style.textFont
            font.pixelSize: 40
            font.bold: true
            color: Colors.primary
            opacity: 0.7
        }

        Rectangle {
            id: darken
            anchors.fill: parent
            color: "black"
            opacity: root.selected ? 0 : (root._hovered ? 0.15 : 0.4)
            Behavior on opacity { NumberAnimation { duration: Style.animNormal } }
        }

        // Legibility scrim behind the name -- spec gives the text style
        // ("10px Bold weiß") but not a backing, so a plain bottom gradient
        // is added rather than risking white-on-artwork illegibility.
        Rectangle {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            height: 36
            gradient: Gradient {
                GradientStop { position: 0.0; color: "transparent" }
                GradientStop { position: 1.0; color: Qt.rgba(0, 0, 0, 0.6) }
            }
        }

        Text {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.margins: 8
            elide: Text.ElideRight
            text: (root.modelData.name || "").toUpperCase()
            font.family: Style.textFont
            font.pixelSize: 10
            font.bold: true
            color: "white"
        }
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor

        property point _enterPos: Qt.point(0, 0)
        property bool _passedThreshold: false

        onEntered: {
            _enterPos = Qt.point(mouseX, mouseY);
            _passedThreshold = false;
        }
        onPositionChanged: mouse => {
            if (_passedThreshold)
                return;
            const dx = mouse.x - _enterPos.x;
            const dy = mouse.y - _enterPos.y;
            if (Math.hypot(dx, dy) > 2) {
                _passedThreshold = true;
                root.selectRequested();
            }
        }
        onClicked: {
            if (root.selected)
                root.activated();
            else
                root.selectRequested();
        }
    }
}
