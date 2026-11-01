pragma Singleton
pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pipewire

// Zentraler Zustand: offenes Menü, mango-IPC, Audio, Systemwerte, Toasts, Timer.
Singleton {
    id: root

    // ── Menüs ──
    property string menu: ""
    function toggle(name) { menu = (menu === name) ? "" : name }
    function open(name) { menu = name }
    function close() { menu = "" }

    // ── mango ──
    property var tags: []
    property string layoutSymbol: ""
    property string kbLayout: ""
    property string title: ""
    property string appId: ""
    property string monitorName: ""

    function dispatch(arg) { Quickshell.execDetached(["mmsg", "dispatch", arg]) }
    function view(i) { dispatch("view," + i + ",0") }

    Process {
        id: monWatch
        running: true
        command: ["mmsg", "watch", "all-monitors"]
        stdout: SplitParser { onRead: line => root.parseMon(line) }
        onRunningChanged: if (!running) monRestart.start()
    }
    Timer { id: monRestart; interval: 2000; onTriggered: monWatch.running = true }

    Process {
        id: focusWatch
        running: true
        command: ["mmsg", "watch", "focusing-client"]
        stdout: SplitParser {
            onRead: line => {
                let c
                try { c = JSON.parse(line) } catch (e) { return }
                root.title = c.title ?? ""
                root.appId = c.appid ?? ""
            }
        }
        onRunningChanged: if (!running) focusRestart.start()
    }
    Timer { id: focusRestart; interval: 2000; onTriggered: focusWatch.running = true }

    function parseMon(line) {
        let j
        try { j = JSON.parse(line) } catch (e) { return }
        const ms = j.monitors ?? []
        if (!ms.length) return
        const m = ms.find(x => x.active) ?? ms[0]
        monitorName = m.name
        tags = m.tags ?? []
        layoutSymbol = m.layout_symbol ?? ""
        const kb = m.keyboardlayout ?? ""
        if (kbLayout !== "" && kb !== kbLayout) toast(Icons.keyboard, kb)
        kbLayout = kb
        const c = m.active_client
        title = c ? (c.title ?? "") : ""
        appId = c ? (c.appid ?? "") : ""
    }

    // ── Audio (Pipewire direkt, braucht kein DBus) ──
    readonly property PwNode sink: Pipewire.defaultAudioSink
    readonly property PwNode source: Pipewire.defaultAudioSource
    PwObjectTracker { objects: [root.sink, root.source] }

    readonly property real volume: sink?.audio?.volume ?? 0
    readonly property bool muted: sink?.audio?.muted ?? true
    readonly property real micVolume: source?.audio?.volume ?? 0
    readonly property bool micMuted: source?.audio?.muted ?? true

    function setVolume(v) {
        if (!sink?.audio) return
        sink.audio.muted = false
        sink.audio.volume = Math.max(0, Math.min(1, v))
    }
    function setMic(v) {
        if (!source?.audio) return
        source.audio.muted = false
        source.audio.volume = Math.max(0, Math.min(1, v))
    }
    function volIcon(v, m) {
        if (m || v <= 0.001) return Icons.volMute
        return v < 0.34 ? Icons.volLow : v < 0.67 ? Icons.volMid : Icons.volHigh
    }

    property bool audioReady: false
    Timer { interval: 1500; running: true; onTriggered: root.audioReady = true }
    Connections {
        target: root.sink?.audio ?? null
        ignoreUnknownSignals: true
        function onVolumeChanged() { root.volToast() }
        function onMutedChanged() { root.volToast() }
    }
    function volToast() {
        if (audioReady && menu !== "control")
            toast(volIcon(volume, muted), muted ? "Stumm" : Math.round(volume * 100) + "%", muted ? 0 : volume)
    }

    // ── Toast / OSD ──
    property string toastIcon: ""
    property string toastText: ""
    property real toastValue: -1
    property int toastSerial: 0
    function toast(icon, text, value) {
        toastIcon = icon
        toastText = text
        toastValue = value === undefined ? -1 : value
        toastSerial++
    }

    // ── Systemwerte ──
    property real cpu: 0
    property real mem: 0
    property real memUsed: 0
    property real memTotal: 0
    property real cpuTemp: 0
    property real gpuTemp: 0
    property real uptime: 0
    property string load: ""
    property real diskUsed: 0
    property real diskTotal: 0
    property var cpuHist: []
    property var memHist: []
    property var _prev: null
    property var procs: []

    Process {
        id: sys
        command: ["sh", Quickshell.shellDir + "/scripts/sys.sh"]
        stdout: StdioCollector { onStreamFinished: root.parseSys(text) }
    }
    Timer {
        interval: root.menu === "system" ? 1000 : 3000
        running: true; repeat: true; triggeredOnStart: true
        onTriggered: sys.running = true
    }
    function push(arr, v) {
        const a = arr.slice(-59)
        a.push(v)
        return a
    }
    function parseSys(t) {
        for (const line of t.split("\n")) {
            const p = line.trim().split(/\s+/)
            switch (p[0]) {
            case "cpu": {
                const tot = +p[1], idle = +p[2]
                if (_prev) {
                    const dt = tot - _prev[0], di = idle - _prev[1]
                    if (dt > 0) cpu = Math.max(0, Math.min(1, 1 - di / dt))
                }
                _prev = [tot, idle]
                break
            }
            case "mem":
                memTotal = +p[1]; memUsed = +p[1] - +p[2]
                mem = memTotal > 0 ? memUsed / memTotal : 0
                break
            case "up": uptime = +p[1]; break
            case "load": load = p.slice(1, 4).join("  "); break
            case "cpuT": cpuTemp = +p[1] / 1000; break
            case "gpuT": gpuTemp = +p[1] / 1000; break
            case "disk": diskUsed = +p[1]; diskTotal = +p[2]; break
            }
        }
        cpuHist = push(cpuHist, cpu)
        memHist = push(memHist, mem)
    }

    Process {
        id: ps
        command: ["ps", "-eo", "comm,%cpu,%mem", "--sort=-%cpu", "--no-headers"]
        stdout: StdioCollector {
            onStreamFinished: {
                root.procs = text.trim().split("\n").slice(0, 6).map(l => {
                    const p = l.trim().split(/\s+/)
                    const m = p.pop(), c = p.pop()
                    return { name: p.join(" "), cpu: +c, mem: +m }
                })
            }
        }
    }
    Timer {
        interval: 2000; repeat: true; triggeredOnStart: true
        running: root.menu === "system"
        onTriggered: ps.running = true
    }

    function fmtUptime(s) {
        const d = Math.floor(s / 86400), h = Math.floor(s % 86400 / 3600), m = Math.floor(s % 3600 / 60)
        return (d ? d + "T " : "") + (h ? h + "h " : "") + m + "min"
    }

    // ── Wallpaper ──
    property var wallpapers: []
    Process {
        id: wallList
        command: ["sh", "-c", "find \"$1\" -maxdepth 1 -type f \\( -iname '*.png' -o -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.webp' \\) | sort", "sh", Theme.cfg.wallDir]
        stdout: StdioCollector { onStreamFinished: root.wallpapers = text.trim().split("\n").filter(x => x !== "") }
    }
    function refreshWalls() { wallList.running = true }
    function setWallpaper(path) {
        Quickshell.execDetached(["awww", "img", path, "--transition-type", "grow",
                                 "--transition-pos", "0.5,0.5", "--transition-duration", "1.3",
                                 "--transition-fps", "165"])
        Theme.cfg.seedPick = -1
        Theme.wallpaper = path
        toast(Icons.palette, "Farben passen sich an")
    }

    // ── Timer (Kalender-Menü) ──
    property int timerLeft: 0
    property int timerTotal: 0
    property bool timerRunning: false
    function startTimer(min) { timerTotal = min * 60; timerLeft = timerTotal; timerRunning = true }
    function stopTimer() { timerRunning = false; timerLeft = 0; timerTotal = 0 }
    Timer {
        interval: 1000; repeat: true; running: root.timerRunning
        onTriggered: {
            root.timerLeft--
            if (root.timerLeft <= 0) {
                root.stopTimer()
                root.toast(Icons.timer, "Timer abgelaufen!")
            }
        }
    }
    function fmtTimer(s) {
        const m = Math.floor(s / 60), r = s % 60
        return m + ":" + (r < 10 ? "0" : "") + r
    }
}
