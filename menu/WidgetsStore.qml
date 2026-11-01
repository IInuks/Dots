pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Settings of the salbei desktop widgets for the "Widgets" tab. Same pattern
// as BlobStore: the menu is the only writer of salbei-widgets.json, salbei
// (services/WidgetSettings.qml) watches the file and applies every change
// live -- also with another bar active, via the widgets-only host
// (bars/salbei/widgets.qml, started by scripts/widgets-host.sh). Slider drags and preview drags are coalesced by _writeTimer.
//
// Every widget <w> has <w>Visible, <w>X / <w>Y (top-left in % of the screen,
// salbei clamps it on screen, Y 100 = bottom edge), <w>Adapt (ink follows the
// wallpaper brightness under it) and -- except the visualizer -- <w>Backdrop
// (glass card). `widgets` describes each one for the tab: list row, preview
// and the settings below it (`settings`, rendered generically by WidgetsStep).
QtObject {
    id: root

    readonly property string bar: "salbei"
    readonly property string barPath: Quickshell.shellDir + "/../bars/salbei"
    readonly property bool loaded: _loaded
    property bool _loaded: false

    // Selected list entry (a widget id or "accent"); kept here because the
    // tab page is recreated on every tab switch.
    property string selected: "clock"

    readonly property var widgets: [
        {
            id: "clock", name: "Uhr", icon: "", title: "Große Uhrzeit",
            description: "Große Ziffern in der Akzentfarbe, die beim Wechsel einzeln nach oben rollen.",
            backdrop: true,
            settings: [
                { type: "toggle", key: "clock24h", label: "24 Stunden" },
                { type: "toggle", key: "clockSeconds", label: "Sekunden", hint: "aktualisiert jede Sekunde" },
                { type: "slider", key: "clockSize", label: "Größe", from: 48, to: 240, decimals: 0, suffix: " px" }
            ]
        },
        {
            id: "analog", name: "Analoge Uhr", icon: "󰅐", title: "Zifferblatt mit Zeigern",
            description: "Runde Uhr mit Stunden- und Minutenzeiger, Sekundenzeiger in der Akzentfarbe.",
            backdrop: true,
            settings: [
                { type: "toggle", key: "analogSeconds", label: "Sekundenzeiger", hint: "aktualisiert jede Sekunde" },
                { type: "toggle", key: "analogNumbers", label: "Ziffern", hint: "12 · 3 · 6 · 9" },
                { type: "toggle", key: "analogTicks", label: "Minutenstriche" },
                { type: "slider", key: "analogSize", label: "Größe", from: 80, to: 400, decimals: 0, suffix: " px" }
            ]
        },
        {
            id: "calendar", name: "Kalender", icon: "", title: "Monatsansicht + Termine",
            description: "Monat mit heutigem Tag, blättern mit ‹ ›. Daneben das Datum und eine Termin-Spalte.",
            backdrop: true,
            settings: [
                { type: "toggle", key: "calendarWeekNumbers", label: "Kalenderwochen", hint: "Spalte mit ISO-Wochennummern" },
                { type: "toggle", key: "calendarEvents", label: "Termin-Spalte", hint: "Datum + „No events.“ daneben" },
                { type: "slider", key: "calendarWidth", label: "Breite", from: 220, to: 520, decimals: 0, suffix: " px" }
            ]
        },
        {
            id: "visualizer", name: "Visualizer", icon: "", title: "Audio-Balken",
            description: "Dünne Balken mit Glockenkurve, Bass in der Mitte. Erscheint nur, solange Ton spielt. Braucht cava (strat arch pacman -S cava); aus = cava wird nie gestartet.",
            backdrop: false,
            settings: [
                { type: "slider", key: "visualizerWidth", label: "Breite", from: 20, to: 100, decimals: 0, suffix: " %" },
                { type: "slider", key: "visualizerHeight", label: "Höhe", from: 24, to: 200, decimals: 0, suffix: " px" }
            ]
        },
        {
            id: "greeting", name: "Begrüßung", icon: "", title: "Tageszeit-Gruß + Datum",
            description: "„Good evening, Name“ passend zur Tageszeit, darunter das ausgeschriebene Datum in der Akzentfarbe.",
            backdrop: true,
            settings: [
                { type: "text", key: "greetingName", label: "Name", placeholder: "leer = Benutzername" },
                { type: "toggle", key: "greetingDate", label: "Datum zeigen" },
                { type: "slider", key: "greetingScale", label: "Größe", from: 0.6, to: 2.5, decimals: 2, suffix: " ×" }
            ]
        },
        {
            id: "media", name: "Musik", icon: "", title: "Was gerade läuft (MPRIS)",
            description: "Cover, Titel und Interpret des aktiven Players mit Zurück / Play / Weiter. Die Knöpfe sind klickbar.",
            backdrop: true,
            settings: [
                { type: "toggle", key: "mediaArt", label: "Cover" },
                { type: "toggle", key: "mediaControls", label: "Steuerung", hint: "Zurück · Play/Pause · Weiter" },
                { type: "toggle", key: "mediaAutoHide", label: "Ohne Player ausblenden" },
                { type: "slider", key: "mediaScale", label: "Größe", from: 0.6, to: 2, decimals: 2, suffix: " ×" }
            ]
        },
        {
            id: "system", name: "System", icon: "", title: "CPU · RAM · Temperatur",
            description: "Auslastung als Ringe, alle 2 s aktualisiert (dieselben Werte wie in der Bar).",
            backdrop: true,
            settings: [
                { type: "toggle", key: "systemCpu", label: "CPU" },
                { type: "toggle", key: "systemRam", label: "Arbeitsspeicher" },
                { type: "toggle", key: "systemTemp", label: "Temperatur" },
                { type: "slider", key: "systemScale", label: "Größe", from: 0.6, to: 2, decimals: 2, suffix: " ×" }
            ]
        },
        {
            id: "weather", name: "Wetter", icon: "", title: "Aktuelles Wetter (wttr.in)",
            description: "Temperatur, Wetterlage, Höchst-/Tiefstwert und Luftfeuchte von wttr.in, alle 30 min. Ohne Ort rät wttr.in ihn über die IP.",
            backdrop: true,
            settings: [
                { type: "text", key: "weatherCity", label: "Ort", placeholder: "z. B. Wien – leer = automatisch" },
                { type: "toggle", key: "weatherFahrenheit", label: "Fahrenheit" },
                { type: "toggle", key: "weatherDetails", label: "Details", hint: "Höchst/Tief · Luftfeuchte · Ort" },
                { type: "slider", key: "weatherScale", label: "Größe", from: 0.6, to: 2, decimals: 2, suffix: " ×" }
            ]
        }
    ]
    readonly property var widgetIds: widgets.map(w => w.id)
    function meta(id: string): var { return widgets.find(w => w.id === id) ?? null; }

    // value of a key in salbei-widgets.json (bindings track it)
    function v(key: string): var { return file.adapter[key]; }
    readonly property int visibleCount: widgetIds.filter(id => file.adapter[id + "Visible"]).length

    readonly property string accentMode: file.adapter.accentMode
    readonly property string accentColor: file.adapter.accentColor
    readonly property int accentPick: file.adapter.accentPick

    // What salbei found in the wallpaper (salbei writes salbei-palette.json,
    // AccentSource.qml): pastel accent candidates + a small color grid that
    // the preview uses for the same light/dark decision as the desktop.
    readonly property var wallCandidates: _palette.candidates
    readonly property var presets: ["#A8D5A2", "#9FD3C7", "#A7C7E7", "#C3B1E1", "#E8B4B8", "#F2C894"]
    readonly property color currentAccent: accentMode === "wallpaper" && wallCandidates.length > 0
        ? wallCandidates[Math.max(0, Math.min(wallCandidates.length - 1, accentPick))]
        : accentColor
    // current wallpaper (awww), for the preview background
    property string wallpaper: ""

    // Same as salbei's AccentSource.lumAt: average luminance 0..1 of the
    // wallpaper inside a rect given in screen fractions.
    function lumAt(x0: real, y0: real, x1: real, y1: real): real {
        const g = _palette.grid, gw = _palette.gridW, gh = _palette.gridH;
        if (g.length !== gw * gh * 3 || gw === 0) return 0.2;
        const cx0 = Math.max(0, Math.min(gw - 1, Math.floor(x0 * gw)));
        const cx1 = Math.max(cx0, Math.min(gw - 1, Math.ceil(x1 * gw) - 1));
        const cy0 = Math.max(0, Math.min(gh - 1, Math.floor(y0 * gh)));
        const cy1 = Math.max(cy0, Math.min(gh - 1, Math.ceil(y1 * gh) - 1));
        let sum = 0, n = 0;
        for (let y = cy0; y <= cy1; y++)
            for (let x = cx0; x <= cx1; x++) {
                const i = (y * gw + x) * 3;
                sum += (0.2126 * g[i] + 0.7152 * g[i + 1] + 0.0722 * g[i + 2]) / 255;
                n++;
            }
        return n ? sum / n : 0.2;
    }

    property FileView _palette: FileView {
        path: Quickshell.env("HOME") + "/.local/state/quickshell/salbei-palette.json"
        watchChanges: true
        printErrors: false
        property var candidates: []
        property var grid: []
        property int gridW: 0
        property int gridH: 0
        onFileChanged: reload()
        onLoaded: {
            let d = {};
            try { d = JSON.parse(text()); } catch (e) {}
            candidates = d.candidates ?? [];
            grid = d.grid ?? [];
            gridW = d.gridW ?? 0;
            gridH = d.gridH ?? 0;
        }
    }

    function set(key: string, value): void {
        if (!root._loaded) return;
        file.adapter[key] = value;
        root._writeTimer.restart();
    }

    // position of one widget back to its default
    function resetPosition(id: string): void {
        set(id + "X", _defaults[id + "X"]);
        set(id + "Y", _defaults[id + "Y"]);
    }

    function resetDefaults(): void {
        const d = root._defaults;
        for (const k in d) file.adapter[k] = d[k];
        root._writeTimer.restart();
    }

    readonly property var _defaults: ({
        clockVisible: true, clockX: 2.5, clockY: 13, clockAdapt: true, clockBackdrop: false,
        clockSize: 112, clock24h: true, clockSeconds: false,
        analogVisible: false, analogX: 2.5, analogY: 45, analogAdapt: true, analogBackdrop: false,
        analogSize: 180, analogSeconds: true, analogNumbers: false, analogTicks: true,
        calendarVisible: true, calendarX: 79.2, calendarY: 5.4, calendarAdapt: true, calendarBackdrop: false,
        calendarWeekNumbers: true, calendarEvents: true, calendarWidth: 330,
        visualizerVisible: true, visualizerX: 17.5, visualizerY: 100, visualizerAdapt: true,
        visualizerWidth: 65, visualizerHeight: 64,
        greetingVisible: false, greetingX: 2.5, greetingY: 24, greetingAdapt: true, greetingBackdrop: false,
        greetingScale: 1, greetingName: "", greetingDate: true,
        mediaVisible: false, mediaX: 2.5, mediaY: 80, mediaAdapt: true, mediaBackdrop: true,
        mediaScale: 1, mediaArt: true, mediaControls: true, mediaAutoHide: true,
        systemVisible: false, systemX: 86, systemY: 80, systemAdapt: true, systemBackdrop: false,
        systemScale: 1, systemCpu: true, systemRam: true, systemTemp: true,
        weatherVisible: false, weatherX: 2.5, weatherY: 33, weatherAdapt: true, weatherBackdrop: false,
        weatherScale: 1, weatherCity: "", weatherFahrenheit: false, weatherDetails: true,
        accentMode: "fixed", accentColor: "#A8D5A2", accentPick: 0
    })

    property Timer _writeTimer: Timer {
        interval: 60
        onTriggered: file.writeAdapter()
    }

    property FileView file: FileView {
        path: Quickshell.env("HOME") + "/.local/state/quickshell/salbei-widgets.json"
        // Not watched: we're the only writer (see BlobStore).
        watchChanges: false
        atomicWrites: true
        printErrors: false

        // Same keys and defaults as _defaults (and salbei's WidgetSettings).
        adapter: JsonAdapter {
            property bool clockVisible: true
            property real clockX: 2.5
            property real clockY: 13
            property bool clockAdapt: true
            property bool clockBackdrop: false
            property real clockSize: 112
            property bool clock24h: true
            property bool clockSeconds: false

            property bool analogVisible: false
            property real analogX: 2.5
            property real analogY: 45
            property bool analogAdapt: true
            property bool analogBackdrop: false
            property real analogSize: 180
            property bool analogSeconds: true
            property bool analogNumbers: false
            property bool analogTicks: true

            property bool calendarVisible: true
            property real calendarX: 79.2
            property real calendarY: 5.4
            property bool calendarAdapt: true
            property bool calendarBackdrop: false
            property bool calendarWeekNumbers: true
            property bool calendarEvents: true
            property real calendarWidth: 330

            property bool visualizerVisible: true
            property real visualizerX: 17.5
            property real visualizerY: 100
            property bool visualizerAdapt: true
            property real visualizerWidth: 65
            property real visualizerHeight: 64

            property bool greetingVisible: false
            property real greetingX: 2.5
            property real greetingY: 24
            property bool greetingAdapt: true
            property bool greetingBackdrop: false
            property real greetingScale: 1
            property string greetingName: ""
            property bool greetingDate: true

            property bool mediaVisible: false
            property real mediaX: 2.5
            property real mediaY: 80
            property bool mediaAdapt: true
            property bool mediaBackdrop: true
            property real mediaScale: 1
            property bool mediaArt: true
            property bool mediaControls: true
            property bool mediaAutoHide: true

            property bool systemVisible: false
            property real systemX: 86
            property real systemY: 80
            property bool systemAdapt: true
            property bool systemBackdrop: false
            property real systemScale: 1
            property bool systemCpu: true
            property bool systemRam: true
            property bool systemTemp: true

            property bool weatherVisible: false
            property real weatherX: 2.5
            property real weatherY: 33
            property bool weatherAdapt: true
            property bool weatherBackdrop: false
            property real weatherScale: 1
            property string weatherCity: ""
            property bool weatherFahrenheit: false
            property bool weatherDetails: true

            property string accentMode: "fixed"
            property string accentColor: "#A8D5A2"
            property int accentPick: 0
        }

        onLoaded: root._loaded = true
        onLoadFailed: root._loaded = true
    }

    // -- salbei process ---------------------------------------------------
    // The widgets run in salbei itself, or -- with any other bar active --
    // in the widgets-only host bars/salbei/widgets.qml (scripts/widgets-host.sh).
    property bool running: false
    readonly property bool hosted: BarsModel.activeBar !== bar

    function refresh(): void {
        file.reload();
        _palette.reload();
        _sync.running = true;
        _wall.running = true;
    }

    // make sure the host runs (or not) for the active bar, then check
    property Process _sync: Process {
        command: [Quickshell.shellDir + "/scripts/widgets-host.sh", "sync"]
        onExited: root._check.running = true
    }

    property Process _check: Process {
        command: ["pgrep", "-f", "^qs -p " + root.barPath + "(/widgets\\.qml)?( |$)"]
        onExited: code => root.running = code === 0
    }

    property Process _wall: Process {
        command: ["sh", "-c", "awww query 2>/dev/null | sed -n 's/.*image: //p' | head -1"]
        stdout: StdioCollector {
            onStreamFinished: root.wallpaper = text.trim()
        }
    }
}
