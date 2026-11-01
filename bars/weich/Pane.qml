import QtQuick
import QtQuick.Effects

// A single soft, floating pill segment. Several of these sit inside one
// window with visible gaps between them (see LeftCluster/RightCluster) --
// that's what keeps the bar from reading as one continuous strip while
// still letting each window span from screen edge to screen edge.
Item {
    id: pane

    default property alias content: row.data
    property real cornerRadius: Theme.pillRadius
    property bool interactive: false
    property bool hovered: false

    signal clicked()
    signal rightClicked()
    signal wheel(int angleDelta)
    signal middleClicked()

    implicitWidth: row.implicitWidth + Theme.paddingH * 2
    implicitHeight: Theme.paneHeight

    MultiEffect {
        anchors.fill: bg
        source: bg
        shadowEnabled: true
        shadowColor: Qt.rgba(0, 0, 0, Theme.shadowOpacity)
        shadowBlur: Theme.shadowBlur
        shadowVerticalOffset: 3
        shadowHorizontalOffset: 0
        blurMax: 32
    }

    Rectangle {
        id: bg
        anchors.fill: parent
        radius: pane.cornerRadius
        color: Theme.paneColor
        border.width: 1
        border.color: Theme.hairline
        Behavior on color { ColorAnimation { duration: Theme.animSoft } }
    }

    Rectangle {
        id: hoverOverlay
        anchors.fill: bg
        radius: pane.cornerRadius
        color: Theme.foreground
        opacity: pane.hovered ? 0.07 : 0
        Behavior on opacity { NumberAnimation { duration: Theme.animFast } }
    }

    Row {
        id: row
        anchors.centerIn: parent
        spacing: Theme.itemSpacing
    }

    MouseArea {
        anchors.fill: parent
        enabled: pane.interactive
        hoverEnabled: pane.interactive
        acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
        cursorShape: pane.interactive ? Qt.PointingHandCursor : Qt.ArrowCursor
        onEntered: pane.hovered = true
        onExited: pane.hovered = false
        onClicked: mouse => {
            if (mouse.button === Qt.RightButton) pane.rightClicked();
            else if (mouse.button === Qt.MiddleButton) pane.middleClicked();
            else pane.clicked();
        }
        onWheel: wheel => pane.wheel(wheel.angleDelta.y)
    }
}
