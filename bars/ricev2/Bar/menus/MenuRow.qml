import QtQuick
import "../../"

// One dropdown list row (menus prompt section 0's shared row spec): 14px-
// wide centered icon in primary, a 120px elided name in backgroundText, and
// a right-aligned 32px value in tertiary, 12px spacing between. Used by the
// WLAN/Bluetooth dropdowns; volume rows need their own layout (icon + name
// + slider below) so they don't reuse this directly.
//
// Root is an Item (not a Row) specifically so call sites can drop a
// `MouseArea { anchors.fill: parent }` in as a plain child -- a Row would
// reject that anchor (Row positions every child itself) the same way the
// bar's own widgets did before their Item-wrapper fix.
Item {
    id: root

    property string iconGlyph: ""
    property string label: ""
    property string value: ""
    property bool bold: false
    property color iconColor: Colors.primary
    property color labelColor: Colors.backgroundText

    implicitWidth: layout.implicitWidth
    implicitHeight: 20
    height: 20

    Row {
        id: layout
        anchors.verticalCenter: parent.verticalCenter
        spacing: 12

        Text {
            width: 14
            height: root.height
            verticalAlignment: Text.AlignVCenter
            horizontalAlignment: Text.AlignHCenter
            font.family: Style.iconFont
            font.pixelSize: 12
            color: root.iconColor
            text: root.iconGlyph
        }
        Text {
            width: 120
            height: root.height
            verticalAlignment: Text.AlignVCenter
            elide: Text.ElideRight
            font.family: Style.textFont
            font.pixelSize: 12
            font.weight: Font.Medium
            font.bold: root.bold
            color: root.labelColor
            text: root.label
        }
        Text {
            width: 32
            height: root.height
            verticalAlignment: Text.AlignVCenter
            horizontalAlignment: Text.AlignRight
            font.family: Style.textFont
            font.pixelSize: 12
            font.weight: Font.Medium
            color: Colors.tertiary
            text: root.value
        }
    }
}
