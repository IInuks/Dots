import QtQuick
import ".."

// Window title bar: centered title, minimize/maximize/close on the right.
// Dragging it moves the window (the layer-shell surface is fullscreen, so
// "moving" just offsets the panel inside it -- see shell.qml); double click
// toggles maximize.
Rectangle {
    id: bar

    property string title: ""
    property bool maximized: false

    signal minimizeRequested()
    signal maximizeRequested()
    signal closeRequested()
    signal dragged(real dx, real dy)

    height: Theme.titleBarHeight
    radius: Theme.radius
    color: Theme.titleBar

    // Square off the bottom corners (Rectangle radius is all-or-nothing).
    Rectangle {
        anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
        height: bar.radius
        color: bar.color
    }
    Rectangle {
        anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
        height: 1
        color: Theme.border
    }

    MouseArea {
        id: dragArea
        anchors.fill: parent
        property point last
        cursorShape: pressed ? Qt.ClosedHandCursor : Qt.ArrowCursor
        onPressed: mouse => last = mapToGlobal(mouse.x, mouse.y)
        onPositionChanged: mouse => {
            if (!pressed) return;
            const p = mapToGlobal(mouse.x, mouse.y);
            bar.dragged(p.x - last.x, p.y - last.y);
            last = p;
        }
        onDoubleClicked: bar.maximizeRequested()
    }

    Row {
        anchors.left: parent.left
        anchors.leftMargin: Theme.spacingM
        anchors.verticalCenter: parent.verticalCenter
        spacing: 6
        Repeater {
            model: [Theme.danger, "#e5c07b", Theme.success]
            delegate: Rectangle {
                required property var modelData
                width: 10; height: 10; radius: 5
                color: Qt.alpha(modelData, 0.35)
            }
        }
    }

    Text {
        anchors.centerIn: parent
        text: bar.title
        color: Theme.text
        font.family: Theme.fontFamily
        font.pixelSize: Theme.fontM
        font.weight: Font.DemiBold
    }

    Row {
        anchors.right: parent.right
        anchors.rightMargin: Theme.spacingS
        anchors.verticalCenter: parent.verticalCenter
        spacing: 2

        TitleButton { icon: ""; onClicked: bar.minimizeRequested() }
        TitleButton { icon: bar.maximized ? "" : ""; onClicked: bar.maximizeRequested() }
        TitleButton {
            icon: ""
            hoverColor: Theme.danger
            hoverIconColor: "#ffffff"
            onClicked: bar.closeRequested()
        }
    }
}
