import QtQuick

// Ein Geschenk in der Leiste. Verpackt: Papier, Band, Schleife, Anhaenger.
// Klick packt aus (Papierhaelften fliegen zur Seite, Konfetti), Rechtsklick
// auf ein ausgepacktes Geschenk packt es wieder ein. Der eigentliche Inhalt
// (Uhr, Tags, ...) ist das Kind dieses Items.
Item {
    id: root

    property int paper: 0
    readonly property var look: Theme.paper(paper)
    property string tagIcon: Theme.iGift
    property bool wrapped: Config.bescherungOnStart
    // manual: ein Klick auf das verpackte Geschenk packt nicht selbst aus,
    // sondern meldet sich nur (das Tagesgeschenk entscheidet selbst).
    property bool manual: false
    property bool rewrappable: true
    property bool inBescherung: true
    property Item confetti: null
    property real minWidth: 50
    property real pad: 12
    default property alias content: inner.data

    signal wrappedClicked

    // 0 = verpackt, 1 = ausgepackt; alles Optische haengt nur hieran.
    property real p: wrapped ? 0 : 1
    property real wiggle: 0

    implicitWidth: Math.max(minWidth, inner.childrenRect.width + 2 * pad)
    implicitHeight: Config.bowRoom + Config.boxHeight

    function unwrap() {
        wrapped = false;
    }
    function rewrap() {
        if (rewrappable)
            wrapped = true;
    }

    onWrappedChanged: {
        anim.stop();
        anim.to = wrapped ? 0 : 1;
        anim.duration = wrapped ? 480 : 760;
        anim.easing.type = wrapped ? Easing.InOutBack : Easing.OutCubic;
        anim.start();
        if (!wrapped)
            burstLater.restart();
    }
    NumberAnimation {
        id: anim
        target: root
        property: "p"
    }
    Timer {
        id: burstLater
        interval: 90
        onTriggered: {
            if (!root.confetti)
                return;
            const c = body.mapToItem(root.confetti, body.width / 2, body.height / 2);
            root.confetti.burst(c.x, c.y, [root.look.paper, root.look.ribbon, root.look.stripe, Theme.tissue]);
        }
    }

    Behavior on implicitWidth {
        NumberAnimation {
            duration: 220
            easing.type: Easing.OutCubic
        }
    }

    // Wackeln, solange die Maus ueber einem verpackten Geschenk schwebt
    SequentialAnimation {
        running: hover.containsMouse && root.wrapped
        loops: Animation.Infinite
        onRunningChanged: if (!running) root.wiggle = 0
        NumberAnimation { target: root; property: "wiggle"; to: 5; duration: 70; easing.type: Easing.OutQuad }
        NumberAnimation { target: root; property: "wiggle"; to: -5; duration: 140; easing.type: Easing.InOutQuad }
        NumberAnimation { target: root; property: "wiggle"; to: 3; duration: 110; easing.type: Easing.InOutQuad }
        NumberAnimation { target: root; property: "wiggle"; to: 0; duration: 80 }
        PauseAnimation { duration: 520 }
    }

    Item {
        id: body
        y: Config.bowRoom
        width: root.width
        height: Config.boxHeight
        rotation: root.wiggle
        transformOrigin: Item.Bottom

        // Schatten + Seidenpapier, auf dem der Inhalt liegt
        Rectangle {
            anchors.fill: parent
            anchors.topMargin: 2
            anchors.bottomMargin: -2
            radius: 8
            color: Theme.shadow
            opacity: 0.5
        }
        Rectangle {
            anchors.fill: parent
            radius: 8
            color: Theme.tissue
            border.width: 1
            border.color: Theme.tissueEdge
            // Ausgepackt bleibt ein schmaler Papierstreifen unten stehen
            Rectangle {
                anchors.bottom: parent.bottom
                anchors.horizontalCenter: parent.horizontalCenter
                width: parent.width - 16
                height: 3
                radius: 1.5
                color: root.look.paper
                opacity: root.p
            }
        }

        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.RightButton
            enabled: !root.wrapped
            onClicked: root.rewrap()
        }

        Item {
            id: inner
            anchors.fill: parent
            anchors.leftMargin: root.pad
            anchors.rightMargin: root.pad
            opacity: Math.max(0, (root.p - 0.35) / 0.65)
            enabled: !root.wrapped
        }

        // -- die Verpackung -------------------------------------------------
        Item {
            id: halfL
            width: body.width / 2
            height: body.height
            x: -root.p * (body.width * 0.55 + 14)
            y: root.p * 10
            rotation: -root.p * 22
            opacity: 1 - root.p
            visible: root.p < 0.999
            WrapPaper {
                anchors.fill: parent
                paper: root.paper
                fullWidth: body.width
                offsetX: 0
            }
        }
        Item {
            id: halfR
            width: body.width / 2
            height: body.height
            x: body.width / 2 + root.p * (body.width * 0.55 + 14)
            y: root.p * 10
            rotation: root.p * 22
            opacity: 1 - root.p
            visible: root.p < 0.999
            WrapPaper {
                anchors.fill: parent
                paper: root.paper
                fullWidth: body.width
                offsetX: body.width / 2
            }
        }
        Rectangle {
            // Band quer
            anchors.verticalCenter: parent.verticalCenter
            x: 0
            width: parent.width
            height: 5
            color: root.look.ribbon
            opacity: Math.max(0, 1 - root.p * 2)
            transform: Scale {
                origin.x: body.width / 2
                xScale: 1 - root.p
            }
        }
        Rectangle {
            // Band laengs
            anchors.horizontalCenter: parent.horizontalCenter
            width: 6
            height: parent.height
            color: root.look.ribbon
            opacity: Math.max(0, 1 - root.p * 2)
            transform: Scale {
                origin.y: body.height
                yScale: 1 - root.p
            }
        }
        // Geschenkanhaenger mit einem Hinweis, was drinsteckt
        Rectangle {
            visible: body.width >= 64 && root.p < 0.5
            opacity: 1 - root.p * 2
            x: body.width * 0.25 - width / 2 - 2
            anchors.verticalCenter: parent.verticalCenter
            width: 22
            height: 16
            radius: 4
            color: Theme.tissue
            rotation: -8
            Rectangle {
                width: 3
                height: 3
                radius: 1.5
                x: 2
                anchors.verticalCenter: parent.verticalCenter
                color: Theme.inkSoft
            }
            Text {
                anchors.centerIn: parent
                anchors.horizontalCenterOffset: 2
                text: root.tagIcon
                font.family: Theme.icons
                font.pixelSize: 10
                color: root.look.paper
            }
        }

        Bow {
            anchors.horizontalCenter: parent.horizontalCenter
            y: -Config.bowRoom - 2 - root.p * 18
            ribbon: root.look.ribbon
            scale: 1 + root.p * 0.6
            rotation: root.p * 40
            opacity: 1 - root.p
            visible: root.p < 0.999
        }

        MouseArea {
            id: hover
            anchors.fill: parent
            anchors.topMargin: -Config.bowRoom
            enabled: root.wrapped
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: root.manual ? root.wrappedClicked() : root.unwrap()
        }
    }
}
