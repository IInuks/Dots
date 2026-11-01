import QtQuick

// Horizontal "wrong password" shake on a Translate.
SequentialAnimation {
    id: root
    property Translate shift: null
    property real amount: 12

    NumberAnimation { target: root.shift; property: "x"; to: -root.amount; duration: 50 }
    NumberAnimation { target: root.shift; property: "x"; to: root.amount * 0.8; duration: 70 }
    NumberAnimation { target: root.shift; property: "x"; to: -root.amount * 0.55; duration: 70 }
    NumberAnimation { target: root.shift; property: "x"; to: root.amount * 0.3; duration: 70 }
    NumberAnimation { target: root.shift; property: "x"; to: 0; duration: 60 }
}
