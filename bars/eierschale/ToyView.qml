import QtQuick
import Quickshell

// Die Figuren zum Spielen. Eine Komponente pro Figur, gewählt nach id.
Loader {
    id: root
    property string toyId: ""
    width: parent ? parent.width : 300
    sourceComponent: ({
        wuerfel: dice, muenze: coin, keks: cookie, orakel: ball, blasen: bubbles,
        farbe: colorOfDay, mond: moon, sanduhr: sand, jahr: year, goldei: gold
    })[toyId] || null

    function pick(a) { return a[Math.floor(Math.random() * a.length)]; }

    // ---------------------------------------------------------- Würfel
    Component {
        id: dice
        Column {
            id: diceCol
            spacing: 10
            property int val: 5
            property int spins: 0
            Rectangle {
                id: die
                anchors.horizontalCenter: parent.horizontalCenter
                width: 86; height: 86; radius: 20
                color: Theme.text
                border.width: 3; border.color: Theme.accent
                Grid {
                    anchors.centerIn: parent
                    columns: 3; spacing: 8
                    Repeater {
                        model: 9
                        Rectangle {
                            required property int index
                            readonly property var on: ({ 1: [4], 2: [0, 8], 3: [0, 4, 8], 4: [0, 2, 6, 8], 5: [0, 2, 4, 6, 8], 6: [0, 2, 3, 5, 6, 8] })[diceCol.val]
                            width: 14; height: 14; radius: 7
                            color: Theme.base
                            opacity: on.indexOf(index) >= 0 ? 1 : 0
                        }
                    }
                }
                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: { diceCol.spins = 8; roll.start(); spin.restart(); } }
            }
            NumberAnimation { id: spin; target: die; property: "rotation"; from: 0; to: 720; duration: Theme.ms(700) || 1; easing.type: Easing.OutCubic }
            Timer {
                id: roll
                interval: 70; repeat: true
                onTriggered: { diceCol.val = 1 + Math.floor(Math.random() * 6); if (--diceCol.spins <= 0) stop(); }
            }
            Label { anchors.horizontalCenter: parent.horizontalCenter; text: roll.running ? "…" : "Eine " + diceCol.val + "!"; size: 14; bold: true }
        }
    }

    // ---------------------------------------------------------- Münze
    Component {
        id: coin
        Column {
            id: coinCol
            spacing: 10
            property bool heads: true
            property bool flipping: false
            Rectangle {
                id: c
                anchors.horizontalCenter: parent.horizontalCenter
                width: 90; height: 90; radius: 45
                color: "#e8b93a"
                border.width: 5; border.color: "#c7962a"
                transform: Scale { id: sx; origin.x: 45; xScale: 1 }
                Label { anchors.centerIn: parent; text: parent.parent.heads ? "K" : "Z"; size: 36; bold: true; color: "#7a5a12" }
                MouseArea {
                    anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                    onClicked: if (!parent.parent.flipping) flip.start()
                }
            }
            SequentialAnimation {
                id: flip
                ScriptAction { script: coinCol.flipping = true }
                SequentialAnimation {
                    loops: 5
                    NumberAnimation { target: sx; property: "xScale"; to: 0; duration: Theme.ms(70) || 1 }
                    ScriptAction { script: coinCol.heads = !coinCol.heads }
                    NumberAnimation { target: sx; property: "xScale"; to: 1; duration: Theme.ms(70) || 1 }
                }
                ScriptAction { script: { coinCol.heads = Math.random() < 0.5; coinCol.flipping = false; } }
            }
            Label { anchors.horizontalCenter: parent.horizontalCenter; text: parent.flipping ? "…" : (parent.heads ? "Kopf!" : "Zahl!"); size: 14; bold: true }
        }
    }

    // ---------------------------------------------------------- Glückskeks
    Component {
        id: cookie
        Column {
            spacing: 12
            property string msg: ""
            Rectangle {
                width: parent.width; height: 90; radius: 14
                color: "#fbf1dc"
                Label {
                    id: txt
                    anchors.fill: parent; anchors.margins: 14
                    horizontalAlignment: Text.AlignHCenter
                    wrapMode: Text.WordWrap; elide: Text.ElideNone
                    text: parent.parent.msg.length ? "„" + parent.parent.msg + "“" : "Klick, um den Keks zu brechen."
                    color: "#5b3d1a"; size: 14
                    font.italic: parent.parent.msg.length > 0
                    Behavior on text { SequentialAnimation { NumberAnimation { target: txt; property: "opacity"; to: 0; duration: Theme.tFast } PropertyAction {} NumberAnimation { target: txt; property: "opacity"; to: 1; duration: Theme.tMed } } }
                }
                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: parent.parent.msg = root.pick(Eggs.fortunes) }
            }
        }
    }

    // ---------------------------------------------------------- Orakel
    Component {
        id: ball
        Column {
            id: ballCol
            spacing: 10
            property string answer: "8"
            Rectangle {
                id: b
                anchors.horizontalCenter: parent.horizontalCenter
                width: 120; height: 120; radius: 60
                gradient: Gradient { GradientStop { position: 0; color: "#3a3a48" } GradientStop { position: 1; color: "#0c0c12" } }
                Rectangle {
                    anchors.centerIn: parent
                    width: 74; height: 74; radius: 37
                    color: "#1b2a6b"
                    Label {
                        id: ans
                        anchors.fill: parent; anchors.margins: 8
                        horizontalAlignment: Text.AlignHCenter
                        wrapMode: Text.WordWrap; elide: Text.ElideNone
                        text: parent.parent.parent.answer
                        size: parent.parent.parent.answer.length > 2 ? 11 : 26
                        bold: true; color: "#9fc3ff"
                    }
                }
                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: shake.restart() }
            }
            SequentialAnimation {
                id: shake
                NumberAnimation { target: ans; property: "opacity"; to: 0; duration: Theme.tFast }
                SequentialAnimation {
                    loops: 3
                    NumberAnimation { target: b; property: "rotation"; to: -10; duration: Theme.ms(70) || 1 }
                    NumberAnimation { target: b; property: "rotation"; to: 10; duration: Theme.ms(70) || 1 }
                }
                NumberAnimation { target: b; property: "rotation"; to: 0; duration: Theme.ms(70) || 1 }
                ScriptAction { script: ballCol.answer = root.pick(Eggs.oracle) }
                NumberAnimation { target: ans; property: "opacity"; to: 1; duration: Theme.tSlow }
            }
            Label { anchors.horizontalCenter: parent.horizontalCenter; text: "Frage denken, Kugel klicken"; size: 11.5; color: Theme.textDim }
        }
    }

    // ---------------------------------------------------------- Luftpolster
    Component {
        id: bubbles
        Column {
            id: bw
            spacing: 8
            property int popped: 0
            property int gen: 0
            Grid {
                anchors.horizontalCenter: parent.horizontalCenter
                columns: 8; spacing: 6
                Repeater {
                    model: bw.gen >= 0 ? 24 : 0
                    Item {
                        width: 34; height: 34
                        property bool done: false
                        Connections { target: bw; function onGenChanged() { done = false; } }
                        Rectangle {
                            anchors.centerIn: parent
                            width: parent.done ? 22 : 30; height: width; radius: width / 2
                            color: parent.done ? Theme.alpha(Theme.text, 0.06) : Theme.alpha(Theme.accent, 0.3)
                            border.width: 1; border.color: Theme.alpha(Theme.text, parent.done ? 0.1 : 0.35)
                            Behavior on width { NumberAnimation { duration: Theme.tFast; easing.type: Easing.OutBack } }
                            Rectangle { x: 6; y: 5; width: 7; height: 5; radius: 3; color: "#ffffff"; opacity: parent.parent.done ? 0 : 0.5 }
                        }
                        Label { id: plopp; anchors.centerIn: parent; text: "plopp"; size: 10; bold: true; color: Theme.accent2; opacity: 0 }
                        SequentialAnimation {
                            id: pop
                            ParallelAnimation {
                                NumberAnimation { target: plopp; property: "opacity"; from: 1; to: 0; duration: Theme.ms(500) || 1 }
                                NumberAnimation { target: plopp; property: "anchors.verticalCenterOffset"; from: 0; to: -18; duration: Theme.ms(500) || 1 }
                            }
                        }
                        MouseArea {
                            anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                            onClicked: if (!parent.done) { parent.done = true; bw.popped++; pop.restart(); }
                        }
                    }
                }
            }
            Label {
                anchors.horizontalCenter: parent.horizontalCenter
                text: bw.popped % 24 === 0 && bw.popped > 0 ? "Alle geploppt! Neue Folie…" : bw.popped + " geploppt"
                size: 12; color: Theme.textDim
            }
            Timer { interval: 900; running: bw.popped > 0 && bw.popped % 24 === 0; onTriggered: bw.gen++ }
        }
    }

    // ---------------------------------------------------------- Farbe des Tages
    Component {
        id: colorOfDay
        Item {
            height: childrenRect.height
            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 16
                readonly property color c: {
                    const d = new Date();
                    let h = d.getFullYear() * 372 + d.getMonth() * 31 + d.getDate();
                    h = (h * 2654435761) % 4294967296;
                    return Qt.hsla((h % 360) / 360, 0.55 + (h % 30) / 100, 0.55, 1);
                }
                readonly property string hex: "#" + [c.r, c.g, c.b].map(v => Math.round(v * 255).toString(16).padStart(2, "0")).join("")
                Rectangle {
                    width: 110; height: 110; radius: 24
                    color: parent.c
                    border.width: 1; border.color: Theme.line
                    rotation: -4
                }
                Column {
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 4
                    Label { text: parent.parent.hex.toUpperCase(); size: 22; bold: true; font.family: Theme.mono }
                    Label { text: "rgb(" + [parent.parent.c.r, parent.parent.c.g, parent.parent.c.b].map(v => Math.round(v * 255)).join(", ") + ")"; size: 12; color: Theme.textDim; font.family: Theme.mono }
                    Knopf {
                        id: cp
                        property bool done: false
                        width: 150; height: 30; color: Theme.surface3
                        onClicked: { Quickshell.clipboardText = parent.parent.hex; done = true; }
                        Label { anchors.centerIn: parent; text: cp.done ? "Kopiert!" : "In Zwischenablage"; size: 12 }
                    }
                }
            }
        }
    }

    // ---------------------------------------------------------- Mond
    Component {
        id: moon
        Item {
            height: childrenRect.height
            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 18
                readonly property real age: {
                    const ref = Date.UTC(2000, 0, 6, 18, 14);
                    const syn = 29.530588853;
                    return ((Date.now() - ref) / 86400000 % syn + syn) % syn;
                }
                readonly property real phase: age / 29.530588853    // 0 neu, .5 voll
                readonly property string phaseName: {
                    const p = phase;
                    return p < 0.03 || p > 0.97 ? "Neumond" : p < 0.22 ? "Zunehmende Sichel" : p < 0.28 ? "Erstes Viertel"
                         : p < 0.47 ? "Zunehmender Mond" : p < 0.53 ? "Vollmond" : p < 0.72 ? "Abnehmender Mond"
                         : p < 0.78 ? "Letztes Viertel" : "Abnehmende Sichel";
                }
                Canvas {
                    width: 110; height: 110
                    onPaint: {
                        const ctx = getContext("2d"), r = 50, cx = 55, cy = 55, p = parent.phase;
                        ctx.reset();
                        ctx.fillStyle = "#2a2d3a";
                        ctx.beginPath(); ctx.arc(cx, cy, r, 0, Math.PI * 2); ctx.fill();
                        // beleuchteter Teil: Halbkreis am hellen Rand + Terminator
                        // (Halbellipse mit x-Radius cos(Phase) * r) zurück
                        ctx.fillStyle = "#f3eed8";
                        const waxing = p < 0.5;
                        let k = Math.cos(p * 2 * Math.PI);   // 1 neu .. -1 voll
                        if (Math.abs(k) < 0.001) k = 0.001;
                        ctx.beginPath();
                        ctx.arc(cx, cy, r, -Math.PI / 2, Math.PI / 2, !waxing);
                        ctx.save();
                        ctx.translate(cx, cy);
                        ctx.scale(k, 1);
                        ctx.arc(0, 0, r, Math.PI / 2, -Math.PI / 2, waxing);
                        ctx.restore();
                        ctx.closePath();
                        ctx.fill();
                    }
                }
                Column {
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 4
                    Label { text: parent.parent.phaseName; size: 17; bold: true }
                    Label { text: Math.round(parent.parent.age) + " Tage alt"; size: 12; color: Theme.textDim }
                    Label {
                        readonly property real toFull: ((14.765 - parent.parent.age) % 29.53 + 29.53) % 29.53
                        text: toFull < 0.6 ? "Heute ist Vollmond" : "Vollmond in " + Math.round(toFull) + " Tagen"
                        size: 12; color: Theme.textDim
                    }
                }
            }
        }
    }

    // ---------------------------------------------------------- Sanduhr
    Component {
        id: sand
        Column {
            spacing: 12
            Item {
                anchors.horizontalCenter: parent.horizontalCenter
                width: 110; height: 110
                Ring { anchors.fill: parent; value: Eggs.timerProgress; thickness: 8; tint: Theme.accent2 }
                Label {
                    anchors.centerIn: parent
                    text: {
                        if (Eggs.ringing) return "Um!";
                        if (!Eggs.timerRunning) return "--:--";
                        const s = Math.ceil(Eggs.timerLeft / 1000);
                        return String(Math.floor(s / 60)).padStart(2, "0") + ":" + String(s % 60).padStart(2, "0");
                    }
                    size: 22; bold: true; font.family: Theme.mono
                }
            }
            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 6
                Repeater {
                    model: [1, 5, 10, 25]
                    Knopf {
                        required property int modelData
                        width: 58; height: 32; color: Theme.surface3
                        onClicked: Eggs.startTimer(modelData)
                        Label { anchors.centerIn: parent; text: parent.modelData + " min"; size: 12 }
                    }
                }
                Knopf {
                    width: 40; height: 32; color: Theme.surface3
                    visible: Eggs.timerRunning || Eggs.ringing
                    onClicked: Eggs.stopTimer()
                    Icon { anchors.centerIn: parent; name: "stop"; size: 16; color: Theme.bad }
                }
            }
            Label { anchors.horizontalCenter: parent.horizontalCenter; text: "Läuft weiter, wenn das Menü zu ist. Das Ei klingelt."; size: 11; color: Theme.textFaint }
        }
    }

    // ---------------------------------------------------------- Jahresuhr
    Component {
        id: year
        Column {
            spacing: 10
            readonly property date n: new Date()
            function frac(a, b) { return (n - a) / (b - a); }
            readonly property var rows: {
                const y = n.getFullYear(), m = n.getMonth(), d = n.getDate();
                const wd = (n.getDay() + 6) % 7;
                return [
                    ["Jahr", frac(new Date(y, 0, 1), new Date(y + 1, 0, 1))],
                    ["Monat", frac(new Date(y, m, 1), new Date(y, m + 1, 1))],
                    ["Woche", frac(new Date(y, m, d - wd), new Date(y, m, d - wd + 7))],
                    ["Tag", frac(new Date(y, m, d), new Date(y, m, d + 1))]
                ];
            }
            Repeater {
                model: parent.rows
                Row {
                    required property var modelData
                    required property int index
                    spacing: 10
                    Label { width: 56; text: modelData[0]; size: 12.5; color: Theme.textDim }
                    Rectangle {
                        width: root.width - 130; height: 14; radius: 7
                        anchors.verticalCenter: parent.verticalCenter
                        color: Theme.surface3
                        Rectangle {
                            height: parent.height; radius: 7
                            color: index % 2 ? Theme.accent2 : Theme.accent
                            width: 0
                            Component.onCompleted: width = Math.max(14, parent.width * modelData[1])
                            Behavior on width { NumberAnimation { duration: Theme.ms(900) || 1; easing.type: Easing.OutCubic } }
                        }
                    }
                    Label { width: 50; horizontalAlignment: Text.AlignRight; text: (modelData[1] * 100).toFixed(1) + "%"; size: 12; font.family: Theme.mono }
                }
            }
        }
    }

    // ---------------------------------------------------------- Goldenes Ei
    Component {
        id: gold
        Column {
            spacing: 10
            Item {
                anchors.horizontalCenter: parent.horizontalCenter
                width: 140; height: 130
                Repeater {
                    model: 8
                    Icon {
                        required property int index
                        name: "star"
                        size: 12 + (index % 3) * 4
                        color: "#ffd35c"
                        x: 70 + Math.cos(index / 8 * Math.PI * 2 + spinA.angle) * 62 - width / 2
                        y: 65 + Math.sin(index / 8 * Math.PI * 2 + spinA.angle) * 56 - height / 2
                        opacity: 0.5 + (index % 2) * 0.5
                    }
                }
                QtObject { id: spinA; property real angle: 0 }
                NumberAnimation { target: spinA; property: "angle"; from: 0; to: Math.PI * 2; duration: 9000; loops: Animation.Infinite; running: Theme.motion && root.visible }
                EggShape {
                    anchors.centerIn: parent
                    width: 74; height: 94
                    fill: "#f0b92b"
                    band: "#ffe08a"
                }
            }
            Label {
                width: parent.width; horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.WordWrap; elide: Text.ElideNone
                text: "Nur 3 von 100 Eiern sind golden. Du hast bis jetzt " + Eggs.opened + " Eier geöffnet."
                size: 12.5; color: Theme.textDim
            }
        }
    }
}
