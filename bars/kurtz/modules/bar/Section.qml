import QtQuick
import "../../"
import "../../components"

// A horizontal group of bar modules. In "islands" mode it paints its own
// night-sky capsule behind itself; in "capsule" mode it is transparent.
Item {
    id: root
    property int seed: 1
    default property alias content: row.data

    readonly property real pad: (Theme.barHeight - Theme.pillHeight) / 2

    implicitWidth: row.implicitWidth + pad * 2
    implicitHeight: Theme.barHeight
    width: implicitWidth
    height: implicitHeight

    Behavior on width {
        NumberAnimation { duration: Theme.tMed; easing.type: Theme.easeOut }
    }

    Backdrop {
        anchors.fill: parent
        visible: Theme.islands
        radius: height / 2
        fillAlpha: Theme.c.barAlpha
        starCount: Math.round(root.width / 22)
        seed: root.seed
        nebula: false
        sparkles: false
        twinkle: Theme.c.barTwinkle
        // The bar window ends right below the capsule (see Bar.qml), so a
        // drop shadow would be cut off there with a hard edge.
        shadow: false
    }

    Row {
        id: row
        anchors.verticalCenter: parent.verticalCenter
        x: root.pad
        spacing: Theme.s2
    }
}
