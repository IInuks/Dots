import QtQuick

// Transient notification card, top-right (the dock and its flyouts all
// live at the bottom, so the toast deliberately surfaces somewhere else
// on screen). Lives inside the always-present overlay window, so it's
// visible even while that window's click-through mask is empty -- purely
// visual, no MouseArea, it just times itself out.
Item {
    id: root
    anchors.top: parent.top
    anchors.right: parent.right
    anchors.margins: 18
    width: 288
    height: card.implicitHeight
    z: 50

    readonly property var current: NotifyHub.toast
    visible: current !== null
    opacity: visible ? 1 : 0
    scale: visible ? 1 : 0.9
    Behavior on opacity { NumberAnimation { duration: Chroma.tMed } }
    Behavior on scale { SpringAnimation { spring: 3; damping: 0.4 } }

    onCurrentChanged: if (current !== null) hideTimer.restart()
    Timer {
        id: hideTimer
        interval: 4200
        onTriggered: if (root.current) NotifyHub.clearToast(root.current.id)
    }

    Rectangle {
        id: card
        width: parent.width
        implicitHeight: col.implicitHeight + 22
        radius: Chroma.rMed
        color: Chroma.panelRaised
        border.width: 1
        border.color: Qt.alpha(Chroma.accent, 0.45)

        Column {
            id: col
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: 11
            spacing: 3

            Row {
                spacing: 6
                Glyph { name: "bell"; width: 12; height: 12; tint: Chroma.accent; anchors.verticalCenter: parent.verticalCenter }
                Text {
                    text: root.current ? (root.current.app || "Mitteilung") : ""
                    color: Chroma.textFaint
                    font.family: Metrics.fontFamily
                    font.pixelSize: 10
                    anchors.verticalCenter: parent.verticalCenter
                }
            }
            Text {
                width: parent.width
                visible: root.current && !!root.current.title
                text: root.current ? (root.current.title || "") : ""
                color: Chroma.text
                font.family: Metrics.fontFamily
                font.pixelSize: 13
                font.bold: true
                wrapMode: Text.WordWrap
                maximumLineCount: 2
                elide: Text.ElideRight
            }
            Text {
                width: parent.width
                visible: root.current && !!root.current.body
                text: root.current ? (root.current.body || "") : ""
                color: Chroma.textFaint
                font.family: Metrics.fontFamily
                font.pixelSize: 11
                wrapMode: Text.WordWrap
                maximumLineCount: 2
                elide: Text.ElideRight
            }
        }
    }
}
