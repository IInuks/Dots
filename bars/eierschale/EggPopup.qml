import QtQuick

// Das Überraschungsei. Ablauf:
//   zu      -> Ei in Folie, wackelt beim Drüberfahren
//   klick   -> Ei zittert, Riss läuft einmal herum, Schale springt auf,
//              die gelbe Kapsel hüpft heraus und klappt auf, Funken
//   figur   -> die gezogene Figur zum Spielen + "Noch ein Ei"
// Unten das Sammelregal: gefundene Figuren kann man jederzeit wieder
// anklicken. Leertaste/Enter = nächstes Ei.
PopupCard {
    id: root
    popupId: "egg"
    width: 460

    property string stage: "zu"         // zu | auf | figur
    property var current: null          // Figur aus Eggs.toys
    property bool isNew: false
    readonly property var rarityColor: ({ 1: Theme.textDim, 2: Theme.accent2, 3: "#f0b92b" })

    onShownChanged: if (shown && stage === "auf") reset()

    function reset() {
        openSeq.stop();
        stage = "zu";
        whole.crack = 0; whole.rotation = 0; whole.opacity = 1; whole.scale = 1;
        whole.fill = Qt.binding(() => Theme.text);
        whole.band = Qt.binding(() => Theme.accent);
        top.y = 0; top.x = 0; top.rotation = 0; top.opacity = 0;
        bottom.y = 0; bottom.opacity = 0;
        capsule.scale = 0; capsule.y = 40; capTop.y = 0; capTop.rotation = 0; capsule.opacity = 1;
        prize.scale = 0;
        burst.t = 0;
    }
    function crackOpen() {
        if (stage !== "zu") return;
        const r = Eggs.draw();
        current = r.toy; isNew = r.isNew;
        stage = "auf";
        if (!Theme.motion) { stage = "figur"; prize.scale = 1; whole.opacity = 0; return; }
        openSeq.start();
    }
    function show(toy) {
        reset();
        current = toy; isNew = false;
        whole.opacity = 0;
        stage = "figur";
        prize.scale = 1;
    }
    function again() { reset(); crackOpen(); }

    Connections {
        target: Ui
        function onToyRequested(id) { if (Eggs.toy(id)) root.show(Eggs.toy(id)); }
        function onCrackRequested() { if (root.shown) Qt.callLater(() => root.stage === "zu" ? root.crackOpen() : root.again()); }
    }

    Keys.onSpacePressed: stage === "zu" ? crackOpen() : again()
    Keys.onReturnPressed: stage === "zu" ? crackOpen() : again()

    Column {
        width: parent.width
        spacing: 14

        // ------------------------------------------------ Bühne
        Item {
            id: stageBox
            width: parent.width
            height: 230

            // Tisch-Schatten
            Rectangle {
                anchors.horizontalCenter: parent.horizontalCenter
                y: 196; width: 120; height: 14; radius: 7
                color: Theme.alpha("#000000", 0.25)
                opacity: root.stage === "figur" ? 0 : 1
                Behavior on opacity { NumberAnimation { duration: Theme.tMed } }
            }

            Item {
                id: eggBox
                width: 124; height: 158
                anchors.horizontalCenter: parent.horizontalCenter
                y: 42

                EggShape {
                    id: whole
                    anchors.fill: parent
                    fill: Theme.text
                    band: Theme.accent
                    transformOrigin: Item.Bottom
                    MouseArea {
                        anchors.fill: parent
                        enabled: root.stage === "zu"
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onEntered: if (Theme.motion && !idleWobble.running) idleWobble.start()
                        onClicked: root.crackOpen()
                    }
                }
                EggShape { id: top; width: parent.width; height: parent.height; half: 1; fill: "#6b3b1f"; band: "transparent"; opacity: 0; transformOrigin: Item.Center }
                EggShape { id: bottom; width: parent.width; height: parent.height; half: 2; fill: "#6b3b1f"; band: "transparent"; opacity: 0; shine: false }
            }

            // gelbe Kapsel
            Item {
                id: capsule
                width: 64; height: 76
                anchors.horizontalCenter: parent.horizontalCenter
                y: 40; scale: 0
                Rectangle { id: capBottom; y: 34; width: 64; height: 42; radius: 22; color: Theme.capsule
                    Rectangle { width: parent.width; height: 20; color: parent.color } }
                Rectangle { id: capTop; width: 64; height: 40; radius: 26; color: "#ffe680"; transformOrigin: Item.BottomLeft
                    Rectangle { y: 20; width: parent.width; height: 20; color: parent.color }
                    Rectangle { x: 10; y: 8; width: 14; height: 8; radius: 4; color: "#ffffff"; opacity: 0.6 } }
            }

            // Funken
            Item {
                id: burst
                property real t: 0          // 0..1 Flugfortschritt
                anchors.horizontalCenter: parent.horizontalCenter
                y: 110
                Repeater {
                    model: 14
                    Icon {
                        required property int index
                        readonly property real ang: index / 14 * Math.PI * 2
                        name: index % 3 === 0 ? "star" : "egg"
                        size: 10 + index % 3 * 4
                        color: index % 2 ? Theme.accent : Theme.accent2
                        readonly property real e: 1 - Math.pow(1 - burst.t, 3)     // ease-out
                        x: Math.cos(ang) * (110 + index % 4 * 18) * e - width / 2
                        y: Math.sin(ang) * (80 + index % 3 * 16) * e - height / 2
                        opacity: burst.t > 0 && burst.t < 1 ? 1 - burst.t * burst.t : 0
                        rotation: burst.t * 200
                    }
                }
            }

            // die Figur
            Column {
                id: prize
                anchors.horizontalCenter: parent.horizontalCenter
                y: 18
                spacing: 8
                scale: 0
                visible: scale > 0.01 && root.current !== null
                Rectangle {
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: 108; height: 108; radius: 54
                    color: root.current ? Theme.alpha(root.rarityColor[root.current.rarity], 0.18) : "transparent"
                    border.width: 3
                    border.color: root.current ? root.rarityColor[root.current.rarity] : "transparent"
                    Icon {
                        anchors.centerIn: parent
                        name: root.current ? root.current.glyph : ""
                        size: 56
                        color: root.current && root.current.rarity === 3 ? "#f0b92b" : Theme.text
                    }
                    Rectangle {
                        visible: root.isNew
                        anchors.right: parent.right; anchors.top: parent.top
                        anchors.rightMargin: -14; anchors.topMargin: -2
                        width: newL.implicitWidth + 16; height: 24; radius: 12
                        color: Theme.accent2; rotation: 12
                        Label { id: newL; anchors.centerIn: parent; text: "NEU!"; size: 11.5; bold: true; color: Theme.onAccent }
                    }
                }
                Label { anchors.horizontalCenter: parent.horizontalCenter; text: root.current ? root.current.name : ""; size: 19; bold: true }
                Row {
                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: 6
                    Rectangle {
                        width: rl.implicitWidth + 14; height: 20; radius: 10
                        color: root.current ? Theme.alpha(root.rarityColor[root.current.rarity], 0.2) : "transparent"
                        Label { id: rl; anchors.centerIn: parent; text: root.current ? Eggs.rarityNames[root.current.rarity] : ""; size: 10.5; bold: true; color: root.current ? root.rarityColor[root.current.rarity] : Theme.text }
                    }
                    Label {
                        anchors.verticalCenter: parent.verticalCenter
                        text: root.current ? "Nr. " + (Eggs.indexOf(root.current.id) + 1) + " · " + (Eggs.found[root.current.id] || 0) + "x gefunden" : ""
                        size: 11; color: Theme.textDim
                    }
                }
            }

            Label {
                anchors.horizontalCenter: parent.horizontalCenter
                y: 8
                visible: root.stage === "zu"
                text: "Klick aufs Ei"
                size: 12.5; color: Theme.textDim
            }
        }

        // ------------------------------------------------ Figur zum Spielen
        Column {
            width: parent.width
            spacing: 10
            visible: root.stage === "figur" && root.current !== null
            opacity: visible ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: Theme.tSlow } }
            Label {
                width: parent.width; horizontalAlignment: Text.AlignHCenter
                text: root.current ? root.current.text : ""
                size: 12.5; color: Theme.textDim
            }
            ToyView { toyId: root.current && root.stage === "figur" ? root.current.id : "" }
            Knopf {
                anchors.horizontalCenter: parent.horizontalCenter
                width: 170; height: 38
                color: Theme.accent
                onClicked: root.again()
                Row {
                    anchors.centerIn: parent; spacing: 8
                    Icon { name: "egg"; size: 16; color: Theme.onAccent }
                    Label { text: "Noch ein Ei"; bold: true; color: Theme.onAccent }
                }
            }
        }

        // ------------------------------------------------ Sammelregal
        Rectangle {
            width: parent.width
            height: shelf.height + 46
            radius: 16
            color: Theme.surface2
            Label { x: 14; y: 10; text: "Sammlung"; size: 12; bold: true }
            Label {
                anchors.right: parent.right; anchors.rightMargin: 14; y: 10
                text: Eggs.uniqueFound + " / " + Eggs.toys.length + "  ·  " + Eggs.opened + " Eier"
                size: 11.5; color: Theme.textDim; font.family: Theme.mono
            }
            Grid {
                id: shelf
                x: 10; y: 34
                columns: 10; spacing: 2
                Repeater {
                    model: Eggs.toys
                    delegate: Item {
                        id: slot
                        required property var modelData
                        required property int index
                        readonly property int n: Eggs.found[modelData.id] || 0
                        width: (root.width - root.padding * 2 - 20 - 18) / 10
                        height: 50
                        Rectangle {
                            anchors.fill: parent; radius: 10
                            color: sma.containsMouse && slot.n > 0 ? Theme.alpha(Theme.text, 0.08) : "transparent"
                            border.width: root.current && root.current.id === slot.modelData.id && root.stage === "figur" ? 2 : 0
                            border.color: Theme.accent
                        }
                        Icon {
                            anchors.centerIn: parent; anchors.verticalCenterOffset: -4
                            visible: slot.n > 0
                            name: slot.modelData.glyph; size: 22
                            color: slot.modelData.rarity === 3 ? "#f0b92b" : (slot.modelData.rarity === 2 ? Theme.accent2 : Theme.text)
                            scale: sma.containsMouse ? 1.2 : 1
                            Behavior on scale { NumberAnimation { duration: Theme.tFast; easing.type: Easing.OutBack } }
                        }
                        EggShape {
                            visible: slot.n === 0
                            anchors.centerIn: parent; anchors.verticalCenterOffset: -4
                            width: 16; height: 21
                            fill: "transparent"; outline: Theme.textFaint; shine: false
                            Label { anchors.centerIn: parent; anchors.verticalCenterOffset: 2; text: "?"; size: 10; color: Theme.textFaint }
                        }
                        Label {
                            anchors.horizontalCenter: parent.horizontalCenter
                            anchors.bottom: parent.bottom; anchors.bottomMargin: 2
                            text: slot.n > 0 ? slot.n + "x" : "#" + (slot.index + 1)
                            size: 9.5; color: Theme.textFaint; font.family: Theme.mono
                        }
                        MouseArea {
                            id: sma
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: slot.n > 0 ? Qt.PointingHandCursor : Qt.ArrowCursor
                            onClicked: if (slot.n > 0) root.show(slot.modelData)
                        }
                    }
                }
            }
        }
    }

    // ---------------------------------------------------- Animationen
    SequentialAnimation {
        id: idleWobble
        NumberAnimation { target: whole; property: "rotation"; to: -8; duration: Theme.ms(120); easing.type: Easing.OutQuad }
        NumberAnimation { target: whole; property: "rotation"; to: 6; duration: Theme.ms(160); easing.type: Easing.InOutQuad }
        NumberAnimation { target: whole; property: "rotation"; to: -3; duration: Theme.ms(140) }
        NumberAnimation { target: whole; property: "rotation"; to: 0; duration: Theme.ms(140); easing.type: Easing.OutQuad }
    }

    SequentialAnimation {
        id: openSeq
        // 1. zittern
        SequentialAnimation {
            loops: 4
            NumberAnimation { target: whole; property: "rotation"; to: -6; duration: Theme.ms(45) }
            NumberAnimation { target: whole; property: "rotation"; to: 6; duration: Theme.ms(45) }
        }
        NumberAnimation { target: whole; property: "rotation"; to: 0; duration: Theme.ms(40) }
        // 2. Folie ab (Ei wird Schokolade), Riss läuft
        ParallelAnimation {
            ColorAnimation { target: whole; property: "fill"; to: "#6b3b1f"; duration: Theme.ms(260) }
            ColorAnimation { target: whole; property: "band"; to: "#00000000"; duration: Theme.ms(260) }
        }
        NumberAnimation { target: whole; property: "crack"; from: 0; to: 1; duration: Theme.ms(380); easing.type: Easing.InOutQuad }
        PauseAnimation { duration: Theme.ms(120) }
        // 3. aufspringen
        ScriptAction { script: { top.opacity = 1; bottom.opacity = 1; whole.opacity = 0; } }
        ParallelAnimation {
            NumberAnimation { target: top; property: "y"; to: -70; duration: Theme.ms(520); easing.type: Easing.OutCubic }
            NumberAnimation { target: top; property: "x"; to: -110; duration: Theme.ms(520); easing.type: Easing.OutCubic }
            NumberAnimation { target: top; property: "rotation"; to: -70; duration: Theme.ms(520); easing.type: Easing.OutCubic }
            NumberAnimation { target: top; property: "opacity"; to: 0; duration: Theme.ms(520); easing.type: Easing.InQuad }
            NumberAnimation { target: bottom; property: "y"; to: 18; duration: Theme.ms(420); easing.type: Easing.OutBounce }
            SequentialAnimation {
                PauseAnimation { duration: Theme.ms(80) }
                ParallelAnimation {
                    NumberAnimation { target: capsule; property: "scale"; to: 1; duration: Theme.ms(420); easing.type: Easing.OutBack; easing.overshoot: 2.2 }
                    NumberAnimation { target: capsule; property: "y"; to: 10; duration: Theme.ms(420); easing.type: Easing.OutBack }
                }
            }
        }
        NumberAnimation { target: bottom; property: "opacity"; to: 0; duration: Theme.ms(200) }
        // 4. Kapsel klappt auf, Funken, Figur
        NumberAnimation { target: capTop; property: "rotation"; to: -110; duration: Theme.ms(260); easing.type: Easing.OutBack }
        ScriptAction { script: root.stage = "figur" }
        ParallelAnimation {
            NumberAnimation { target: burst; property: "t"; from: 0; to: 1; duration: Theme.ms(900) }
            NumberAnimation { target: capsule; property: "opacity"; to: 0; duration: Theme.ms(240) }
            NumberAnimation { target: capsule; property: "y"; to: 80; duration: Theme.ms(240) }
            NumberAnimation { target: prize; property: "scale"; from: 0; to: 1; duration: Theme.ms(560); easing.type: Easing.OutBack; easing.overshoot: 2.4 }
        }
    }
}
