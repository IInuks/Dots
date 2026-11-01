import QtQuick

// The bar's single dedicated Command Center trigger: a small glowing
// "core" that breathes continuously and flares brighter + spins slightly
// on hover/open, so it reads as the shell's living center.
Item {
    id: root
    signal clicked()
    implicitWidth: 24
    implicitHeight: 24

    readonly property bool active: MenuState.open

    Rectangle {
        anchors.centerIn: parent
        width: parent.width
        height: parent.height
        radius: width / 2
        color: "transparent"
        border.width: 1.5
        border.color: Theme.accent2
        opacity: root.active ? 0.9 : glowLoop.value
        scale: root.active ? 1.35 : 1
        Behavior on scale { SpringAnimation { spring: 2.5; damping: 0.35 } }
        Behavior on opacity { NumberAnimation { duration: Theme.animMed } }
    }

    QtObject {
        id: glowLoop
        property real value: 0.35
        SequentialAnimation on value {
            loops: Animation.Infinite
            NumberAnimation { to: 0.75; duration: 1300; easing.type: Easing.InOutSine }
            NumberAnimation { to: 0.35; duration: 1300; easing.type: Easing.InOutSine }
        }
    }

    Icon {
        anchors.centerIn: parent
        name: "spark"
        size: 13
        tint: Theme.accent
        filled: true
        rotation: root.active ? 45 : 0
        Behavior on rotation { NumberAnimation { duration: Theme.animMed; easing.type: Easing.OutCubic } }
    }

    MouseArea {
        anchors.fill: parent
        anchors.margins: -6
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
        scale: containsMouse ? 1.15 : 1
        Behavior on scale { SpringAnimation { spring: 3; damping: 0.3 } }
    }
}
