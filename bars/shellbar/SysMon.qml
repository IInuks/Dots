import QtQuick
import QtQuick.Layouts

// Right-cluster CPU% trigger; the liquid menu underneath shows CPU/RAM/GPU
// load plus temperatures. Backed by the shared SysMonData singleton (see
// SysMonData.qml), which also feeds the bigger chart-based Monitor tab in
// SettingsMenu — so the system only gets polled once.
LiquidMenu {
    id: sysMon

    // menuWidth doubles as the popup's cross-axis size (on-screen height on
    // a vertical bar); menuContentHeight doubles as its grow-axis size (how
    // far it extends away from the bar, rightward off a left bar). Shorter
    // and further out on a vertical bar than the horizontal defaults below.
    menuWidth: Settings.vertical ? 200 : 250
    menuContentHeight: Settings.vertical ? 280 : 170

    trigger: Component {
        Item {
            implicitWidth: Settings.vertical ? Settings.barThickness : (label.implicitWidth + 20)
            implicitHeight: Settings.vertical ? (label.implicitHeight + 12) : Settings.barThickness
            Text {
                id: label
                anchors.centerIn: parent
                text: Math.round(SysMonData.cpuPercent) + "%"
                color: Theme.foreground
                font.pixelSize: 13
            }
        }
    }

    content: Component {
        ColumnLayout {
            width: parent.width
            spacing: 10

            MeterRow { label: "CPU"; percent: SysMonData.cpuPercent }
            MeterRow {
                label: "RAM"
                percent: SysMonData.ramPercent
                valueText: SysMonData.ramTotalGB > 0
                    ? SysMonData.ramUsedGB.toFixed(1) + " / " + SysMonData.ramTotalGB.toFixed(0) + " GB"
                    : ""
            }
            MeterRow { label: SysMonData.gpuIsNvidia ? "GPU" : "GPU (amd)"; percent: SysMonData.gpuPercent }

            RowLayout {
                Layout.fillWidth: true
                Layout.topMargin: 4
                Text {
                    text: "CPU " + (SysMonData.cpuTemp > 0 ? Math.round(SysMonData.cpuTemp) + "°C" : "—")
                    color: Theme.mutedText
                    font.pixelSize: 11
                    Layout.fillWidth: true
                }
                Text {
                    text: "GPU " + (SysMonData.gpuTemp > 0 ? Math.round(SysMonData.gpuTemp) + "°C" : "—")
                    color: Theme.mutedText
                    font.pixelSize: 11
                }
            }
        }
    }
}
