pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// CPU-/GPU-Temperatur (Auftrag Abschnitt 6, GPU zusaetzlich fuer den
// Systemmonitor-Tab in Etappe 7 -- "nur wenn Sensor vorhanden"). Sensor-
// Pfade werden einmal beim Start aufgeloest (hwmon-Nummerierung kann sich
// nach einem Reboot aendern, die Namen "k10temp"/"coretemp"/"amdgpu" sind
// stabil), danach nur noch per FileView gelesen -- kein Shell-Prozess im
// Polling-Loop.
QtObject {
    id: root

    // 0 = noch keine Daten (TempBlob zeigt dafuer "--°").
    property real temperatureC: 0
    property bool sensorFound: false
    property real gpuTemperatureC: 0
    property bool gpuSensorFound: false

    // CPU-Auslastung in Prozent (0-100), fuer WorkspaceBlob (linke Kugel).
    // /proc/stat ist immer vorhanden -- kein Sensor-Resolve wie bei der
    // Temperatur noetig, laeuft deshalb ueber einen eigenen, sofort
    // startenden Timer statt ueber pollTimer (der erst nach erfolgreichem
    // hwmon-Fund anlaeuft).
    property real usagePercent: 0
    property var _prevIdle: null
    property var _prevTotal: null

    // Zeile 1 = CPU-Sensorpfad (oder leer), Zeile 2 = GPU-Sensorpfad (oder leer).
    readonly property string _resolveScript: "
        cpu=\"\"
        for d in /sys/class/hwmon/*/; do
            n=$(cat \"$d\"name 2>/dev/null)
            if [ \"$n\" = \"k10temp\" ]; then
                for l in \"$d\"temp*_label; do
                    [ -f \"$l\" ] || continue
                    if [ \"$(cat \"$l\")\" = \"Tctl\" ]; then cpu=\"${l%_label}_input\"; fi
                done
            fi
        done
        if [ -z \"$cpu\" ]; then
            for d in /sys/class/hwmon/*/; do
                n=$(cat \"$d\"name 2>/dev/null)
                if [ \"$n\" = \"coretemp\" ]; then
                    for l in \"$d\"temp*_label; do
                        [ -f \"$l\" ] || continue
                        if [ \"$(cat \"$l\")\" = \"Package id 0\" ]; then cpu=\"${l%_label}_input\"; fi
                    done
                fi
            done
        fi
        gpu=\"\"
        for d in /sys/class/hwmon/*/; do
            n=$(cat \"$d\"name 2>/dev/null)
            if [ \"$n\" = \"amdgpu\" ]; then
                for l in \"$d\"temp*_label; do
                    [ -f \"$l\" ] || continue
                    if [ \"$(cat \"$l\")\" = \"edge\" ]; then gpu=\"${l%_label}_input\"; fi
                done
            fi
        done
        echo \"$cpu\"
        echo \"$gpu\"
    "

    property Process _resolveProc: Process {
        running: true
        command: ["sh", "-c", root._resolveScript]
        stdout: StdioCollector {
            onStreamFinished: {
                const lines = text.split("\n");
                const cpuPath = (lines[0] || "").trim();
                const gpuPath = (lines[1] || "").trim();
                if (cpuPath.length > 0) {
                    root.sensorFound = true;
                    tempFile.path = cpuPath;
                }
                if (gpuPath.length > 0) {
                    root.gpuSensorFound = true;
                    gpuTempFile.path = gpuPath;
                }
                if (cpuPath.length > 0 || gpuPath.length > 0)
                    pollTimer.start();
            }
        }
    }

    property FileView tempFile: FileView {
        id: tempFile
        path: ""
        onLoaded: root._onTempText(tempFile.text())
    }

    property FileView gpuTempFile: FileView {
        id: gpuTempFile
        path: ""
        onLoaded: root._onGpuTempText(gpuTempFile.text())
    }

    property Timer pollTimer: Timer {
        id: pollTimer
        interval: 2000
        repeat: true
        running: false
        triggeredOnStart: true
        onTriggered: {
            if (root.sensorFound)
                tempFile.reload();
            if (root.gpuSensorFound)
                gpuTempFile.reload();
        }
    }

    function _onTempText(text) {
        const v = parseInt(text.trim(), 10);
        // /sys/class/hwmon .../temp*_input ist Millicelsius.
        if (!isNaN(v))
            root.temperatureC = v / 1000;
    }

    function _onGpuTempText(text) {
        const v = parseInt(text.trim(), 10);
        if (!isNaN(v))
            root.gpuTemperatureC = v / 1000;
    }

    property FileView statFile: FileView {
        id: statFile
        path: "/proc/stat"
        onLoaded: root._onStatText(statFile.text())
    }

    property Timer usageTimer: Timer {
        id: usageTimer
        interval: 2000
        repeat: true
        running: true
        triggeredOnStart: true
        onTriggered: statFile.reload()
    }

    function _onStatText(text) {
        // Erste Zeile: "cpu  user nice system idle iowait irq softirq ...".
        const parts = text.split("\n")[0].trim().split(/\s+/).slice(1).map(Number);
        if (parts.length < 4)
            return;
        const idle = parts[3] + (parts[4] || 0);
        const total = parts.reduce((a, b) => a + b, 0);
        // Auslastung braucht ein Delta zwischen zwei Samples -- beim ersten
        // Aufruf nur Baseline merken, noch keinen Wert berechnen.
        if (root._prevIdle !== null) {
            const idleDelta = idle - root._prevIdle;
            const totalDelta = total - root._prevTotal;
            if (totalDelta > 0)
                root.usagePercent = Math.max(0, Math.min(100, 100 * (1 - idleDelta / totalDelta)));
        }
        root._prevIdle = idle;
        root._prevTotal = total;
    }
}
