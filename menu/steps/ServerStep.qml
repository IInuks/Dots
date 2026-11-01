import QtQuick
import Quickshell
import ".."
import "../components"
import "../custom"

// "Server" tab: dashboard of the remote server over Tailscale + SSH
// (ServerStore, which runs salbei's scripts/server.sh every 3 s while this
// page exists and the menu is open). Left: host, status, CPU / RAM / disk
// rings, load / temperature / swap / network, terminal + reconnect.
// Right: CPU + RAM history of the last 3 min, all mounts, top processes and
// the connection settings.
FocusScope {
    id: page

    focus: true
    Component.onCompleted: { ServerStore.watchers++; forceActiveFocus(); }
    Component.onDestruction: ServerStore.watchers--

    readonly property bool ok: ServerStore.status === "ok"
    readonly property color statusColor: ok ? Theme.success
        : ["auth", "check", "offline"].includes(ServerStore.status) ? Theme.danger : Theme.textFaint

    // T = terminal, R = reconnect (not while typing in a field)
    Keys.onPressed: event => {
        if (event.key === Qt.Key_T) { ServerStore.openShell(); event.accepted = true; }
        else if (event.key === Qt.Key_R) { ServerStore.poll(); event.accepted = true; }
    }

    component SectionLabel: Text {
        color: Theme.textFaint
        font.family: Theme.fontFamily
        font.pixelSize: Theme.fontXs
        font.weight: Font.Bold
        font.letterSpacing: 1
    }

    // usage ring with the value in the middle and a label + detail below
    component Ring: Column {
        id: ring
        property real value: 0           // 0..1
        property string label
        property string detail
        property real size: 100
        spacing: Theme.spacingXs
        Item {
            anchors.horizontalCenter: parent.horizontalCenter
            width: ring.size
            height: ring.size
            Canvas {
                id: arc
                anchors.fill: parent
                property real shown: ring.value
                Behavior on shown { NumberAnimation { duration: 600; easing.type: Easing.OutCubic } }
                readonly property color fill: ring.value > 0.9 ? Theme.danger : Theme.accent
                onShownChanged: requestPaint()
                onFillChanged: requestPaint()
                onWidthChanged: requestPaint()
                onPaint: {
                    const ctx = getContext("2d");
                    ctx.reset();
                    if (width < 16) return;
                    const lw = Math.max(4, width * 0.08), r = width / 2 - lw / 2;
                    ctx.lineWidth = lw;
                    ctx.lineCap = "round";
                    ctx.strokeStyle = Theme.panelAlt;
                    ctx.beginPath(); ctx.arc(width / 2, height / 2, r, 0, 2 * Math.PI); ctx.stroke();
                    const v = Math.max(0, Math.min(1, shown));
                    if (v <= 0.005) return;
                    ctx.strokeStyle = fill;
                    ctx.beginPath(); ctx.arc(width / 2, height / 2, r, -Math.PI / 2, -Math.PI / 2 + v * 2 * Math.PI); ctx.stroke();
                }
            }
            Text {
                anchors.centerIn: parent
                text: Math.round(ring.value * 100) + "%"
                color: Theme.text
                font.family: Theme.fontFamily
                font.pixelSize: Math.round(ring.size * 0.22)
                font.weight: Font.Bold
            }
        }
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: ring.label
            color: Theme.textDim
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontS
            font.weight: Font.Bold
            font.letterSpacing: 1
        }
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: ring.detail
            color: Theme.textFaint
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontXs
        }
    }

    // small "label / big value" cell
    component Stat: Column {
        property string label
        property string value
        property bool hot: false
        spacing: 2
        Text { text: parent.label; color: Theme.textFaint; font.family: Theme.fontFamily; font.pixelSize: Theme.fontXs }
        Text {
            text: parent.value
            color: parent.hot ? Theme.danger : Theme.text
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontL
            font.weight: Font.DemiBold
        }
    }

    // thin usage bar
    component UsageBar: Rectangle {
        property real value: 0
        height: 6
        radius: 3
        color: Theme.panelAlt
        Rectangle {
            width: parent.width * Math.max(0, Math.min(1, parent.value))
            height: parent.height
            radius: 3
            color: parent.value > 0.85 ? Theme.danger : Theme.accent
            Behavior on width { NumberAnimation { duration: 400; easing.type: Easing.OutCubic } }
        }
    }

    Row {
        anchors.fill: parent
        spacing: Theme.spacingM

        // -- Overview ----------------------------------------------------
        Panel {
            id: overview
            width: Math.round(parent.width * 0.42)
            height: parent.height

            Item {
                anchors.fill: parent
                anchors.margins: Theme.spacingL

                Row {
                    id: header
                    width: parent.width
                    spacing: Theme.spacingM
                    Rectangle {
                        anchors.verticalCenter: parent.verticalCenter
                        width: 40; height: 40
                        radius: Theme.radiusSmall
                        color: Qt.alpha(page.statusColor, 0.14)
                        Behavior on color { ColorAnimation { duration: Theme.animPage } }
                        Icon {
                            anchors.centerIn: parent
                            text: ""
                            size: 18
                            color: page.statusColor
                        }
                    }
                    Column {
                        anchors.verticalCenter: parent.verticalCenter
                        width: header.width - 40 - header.spacing
                        spacing: 2
                        Text {
                            width: parent.width
                            elide: Text.ElideRight
                            text: page.ok && ServerStore.hostname !== "" ? ServerStore.hostname : ServerStore.host
                            color: Theme.text
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontXl
                            font.weight: Font.Bold
                        }
                        Text {
                            width: parent.width
                            elide: Text.ElideRight
                            text: ({
                                ok: "Linux " + ServerStore.kernel + "  ·  läuft seit " + ServerStore.formatUptime(ServerStore.uptime),
                                connecting: "Verbinde mit " + ServerStore.target + " …",
                                idle: "Verbinde mit " + ServerStore.target + " …",
                                auth: "Login nötig: einmal im Terminal anmelden oder Schlüssel einrichten",
                                check: "Tailscale SSH will eine Bestätigung: Terminal öffnen, Link anklicken",
                                offline: "Nicht erreichbar – läuft Tailscale? (tailscript start)"
                            })[ServerStore.status] ?? ""
                            color: ["auth", "check", "offline"].includes(ServerStore.status) ? Theme.danger : Theme.textDim
                            font.family: Theme.monoFamily
                            font.pixelSize: Theme.fontXs
                        }
                    }
                }

                Row {
                    id: rings
                    anchors { top: header.bottom; topMargin: Theme.spacingXl; horizontalCenter: parent.horizontalCenter }
                    spacing: Theme.spacingL
                    opacity: page.ok ? 1 : 0.4
                    Behavior on opacity { NumberAnimation { duration: Theme.animPage } }
                    readonly property real ringSize: Math.min(104, (overview.width - 2 * Theme.spacingL - 2 * spacing) / 3)
                    Ring {
                        size: rings.ringSize
                        value: ServerStore.cpu
                        label: "CPU"
                        detail: ServerStore.cores + " Kerne"
                    }
                    Ring {
                        size: rings.ringSize
                        value: ServerStore.memUsed / Math.max(1, ServerStore.memTotal)
                        label: "RAM"
                        detail: ServerStore.gib(ServerStore.memUsed) + " / " + ServerStore.gib(ServerStore.memTotal)
                    }
                    Ring {
                        size: rings.ringSize
                        value: ServerStore.rootDisk.used / Math.max(1, ServerStore.rootDisk.total)
                        label: "PLATTE " + ServerStore.rootDisk.mount
                        detail: ServerStore.size(ServerStore.rootDisk.used) + " / " + ServerStore.size(ServerStore.rootDisk.total)
                    }
                }

                Grid {
                    id: stats
                    anchors { top: rings.bottom; topMargin: Theme.spacingXl; left: parent.left; right: parent.right }
                    columns: 4
                    columnSpacing: Theme.spacingM
                    opacity: page.ok ? 1 : 0.4
                    readonly property real cell: (width - 3 * columnSpacing) / 4
                    Stat {
                        width: stats.cell
                        label: "Load"
                        value: ServerStore.load[0].toFixed(2)
                        hot: ServerStore.load[0] > ServerStore.cores
                    }
                    Stat {
                        width: stats.cell
                        label: "Temperatur"
                        value: isNaN(ServerStore.temp) ? "–" : Math.round(ServerStore.temp) + "°C"
                        hot: ServerStore.temp >= 85
                    }
                    Stat {
                        width: stats.cell
                        label: "Swap"
                        value: ServerStore.swapTotal > 0 ? ServerStore.gib(ServerStore.swapUsed) : "–"
                    }
                    Column {
                        width: stats.cell
                        spacing: 2
                        Text { text: "Netz"; color: Theme.textFaint; font.family: Theme.fontFamily; font.pixelSize: Theme.fontXs }
                        Text { text: "↓ " + ServerStore.rate(ServerStore.rxRate); color: Theme.text; font.family: Theme.fontFamily; font.pixelSize: Theme.fontS }
                        Text { text: "↑ " + ServerStore.rate(ServerStore.txRate); color: Theme.text; font.family: Theme.fontFamily; font.pixelSize: Theme.fontS }
                    }
                }

                Row {
                    anchors { left: parent.left; bottom: parent.bottom }
                    spacing: Theme.spacingS
                    WizardButton {
                        text: "Terminal"
                        icon: ""
                        primary: true
                        onClicked: ServerStore.openShell()
                    }
                    WizardButton {
                        text: "Neu verbinden"
                        icon: ""
                        onClicked: ServerStore.poll()
                    }
                    WizardButton {
                        visible: ServerStore.status === "auth"
                        text: "Schlüssel"
                        icon: ""
                        onClicked: ServerStore.setupKey()
                    }
                }
            }
        }

        // -- Details -------------------------------------------------------
        Panel {
            width: parent.width - overview.width - parent.spacing
            height: parent.height

            Flickable {
                id: flick
                anchors.fill: parent
                anchors.margins: Theme.spacingL
                contentHeight: details.implicitHeight
                clip: true
                boundsBehavior: Flickable.StopAtBounds

                Column {
                    id: details
                    width: flick.width
                    spacing: Theme.spacingM

                    // CPU + RAM over the last 3 min
                    Row {
                        width: parent.width
                        SectionLabel { text: "VERLAUF  ·  3 MIN"; width: parent.width - legend.width }
                        Row {
                            id: legend
                            spacing: Theme.spacingM
                            Repeater {
                                model: [{ l: "CPU", c: Theme.accent }, { l: "RAM", c: Theme.select }]
                                Row {
                                    required property var modelData
                                    spacing: 5
                                    Rectangle { anchors.verticalCenter: parent.verticalCenter; width: 10; height: 3; radius: 1.5; color: parent.modelData.c }
                                    Text { text: parent.modelData.l; color: Theme.textDim; font.family: Theme.fontFamily; font.pixelSize: Theme.fontXs }
                                }
                            }
                        }
                    }
                    Rectangle {
                        width: parent.width
                        height: 120
                        radius: Theme.radiusSmall
                        color: Qt.rgba(0, 0, 0, 0.18)
                        border.width: Theme.borderWidth
                        border.color: Theme.border
                        Canvas {
                            id: graph
                            anchors.fill: parent
                            anchors.margins: 8
                            readonly property var cpuData: ServerStore.cpuHistory
                            readonly property var memData: ServerStore.memHistory
                            onCpuDataChanged: requestPaint()
                            onWidthChanged: requestPaint()
                            function line(ctx, data, color) {
                                if (data.length < 2) return;
                                const n = ServerStore.historyLength - 1;
                                const off = n - (data.length - 1);
                                ctx.strokeStyle = color;
                                ctx.lineWidth = 2;
                                ctx.lineJoin = "round";
                                ctx.beginPath();
                                for (let i = 0; i < data.length; i++) {
                                    const x = (off + i) / n * width;
                                    const y = height - Math.max(0, Math.min(1, data[i])) * height;
                                    if (i === 0) ctx.moveTo(x, y); else ctx.lineTo(x, y);
                                }
                                ctx.stroke();
                                // soft fill under the line
                                ctx.lineTo(width, height);
                                ctx.lineTo(off / n * width, height);
                                ctx.closePath();
                                ctx.fillStyle = Qt.alpha(color, 0.10);
                                ctx.fill();
                            }
                            onPaint: {
                                const ctx = getContext("2d");
                                ctx.reset();
                                ctx.strokeStyle = Qt.rgba(1, 1, 1, 0.06);
                                ctx.lineWidth = 1;
                                for (const f of [0.25, 0.5, 0.75]) {
                                    ctx.beginPath();
                                    ctx.moveTo(0, Math.round(height * f) + 0.5);
                                    ctx.lineTo(width, Math.round(height * f) + 0.5);
                                    ctx.stroke();
                                }
                                line(ctx, memData, Theme.select);
                                line(ctx, cpuData, Theme.accent);
                            }
                        }
                        Text {
                            anchors.centerIn: parent
                            visible: ServerStore.cpuHistory.length < 2
                            text: page.ok ? "sammle Werte …" : "keine Daten"
                            color: Theme.textFaint
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontS
                        }
                    }

                    // every mount; the model is just the count, so rows
                    // aren't rebuilt on every poll
                    SectionLabel { text: "LAUFWERKE"; topPadding: Theme.spacingS }
                    Text {
                        visible: ServerStore.disks.length === 0
                        text: "–"
                        color: Theme.textFaint
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontS
                    }
                    Repeater {
                        model: ServerStore.disks.length
                        Row {
                            required property int index
                            readonly property var disk: ServerStore.disks[index] ?? { mount: "", used: 0, total: 0 }
                            width: details.width
                            spacing: Theme.spacingM
                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                width: 130
                                elide: Text.ElideMiddle
                                text: parent.disk.mount
                                color: Theme.text
                                font.family: Theme.monoFamily
                                font.pixelSize: Theme.fontS
                            }
                            UsageBar {
                                anchors.verticalCenter: parent.verticalCenter
                                width: parent.width - 130 - 150 - 2 * parent.spacing
                                value: parent.disk.used / Math.max(1, parent.disk.total)
                            }
                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                width: 150
                                horizontalAlignment: Text.AlignRight
                                text: ServerStore.size(parent.disk.used) + " / " + ServerStore.size(parent.disk.total)
                                color: Theme.textDim
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fontXs
                            }
                        }
                    }

                    // top processes by CPU (ps: average since process start)
                    Row {
                        width: parent.width
                        topPadding: Theme.spacingS
                        SectionLabel { text: "PROZESSE"; width: parent.width - 120 }
                        SectionLabel { text: "Ø CPU"; width: 60; horizontalAlignment: Text.AlignRight }
                        SectionLabel { text: "RAM"; width: 60; horizontalAlignment: Text.AlignRight }
                    }
                    Text {
                        visible: ServerStore.procs.length === 0
                        text: "–"
                        color: Theme.textFaint
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontS
                    }
                    Repeater {
                        model: ServerStore.procs.length
                        Row {
                            required property int index
                            readonly property var proc: ServerStore.procs[index] ?? { cpu: 0, mem: 0, name: "" }
                            width: details.width
                            Text {
                                width: parent.width - 120
                                elide: Text.ElideRight
                                text: parent.proc.name
                                color: Theme.text
                                font.family: Theme.monoFamily
                                font.pixelSize: Theme.fontS
                            }
                            Text {
                                width: 60
                                horizontalAlignment: Text.AlignRight
                                text: parent.proc.cpu.toFixed(1) + "%"
                                color: Theme.accent
                                font.family: Theme.monoFamily
                                font.pixelSize: Theme.fontS
                            }
                            Text {
                                width: 60
                                horizontalAlignment: Text.AlignRight
                                text: parent.proc.mem.toFixed(1) + "%"
                                color: Theme.textDim
                                font.family: Theme.monoFamily
                                font.pixelSize: Theme.fontS
                            }
                        }
                    }

                    // host / fallback / user (menu-server.json)
                    SectionLabel { text: "VERBINDUNG"; topPadding: Theme.spacingS }
                    Row {
                        width: parent.width
                        spacing: Theme.spacingS
                        readonly property real field: (width - 2 * spacing - applyBtn.width - spacing) / 3
                        TextField {
                            id: hostField
                            width: parent.field
                            placeholder: "Host (Tailscale-Name)"
                            text: ServerStore.host
                            onEditingFinished: applyBtn.clicked()
                        }
                        TextField {
                            id: fallbackField
                            width: parent.field
                            placeholder: "Fallback-IP"
                            text: ServerStore.fallback
                            onEditingFinished: applyBtn.clicked()
                        }
                        TextField {
                            id: userField
                            width: parent.field
                            placeholder: "Benutzer (leer = " + Quickshell.env("USER") + ")"
                            text: ServerStore.user
                            onEditingFinished: applyBtn.clicked()
                        }
                        WizardButton {
                            id: applyBtn
                            implicitWidth: 90
                            height: 30
                            text: "Setzen"
                            onClicked: ServerStore.setHost(hostField.text, fallbackField.text, userField.text)
                        }
                    }
                }
            }
        }
    }
}
