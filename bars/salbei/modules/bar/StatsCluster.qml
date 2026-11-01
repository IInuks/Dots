import QtQuick
import "../../"
import "../../services"

Row {
    spacing: Theme.barSpacing

    BarItem { icon: "speed"; text: SystemStats.cpuText; onClicked: Ui.toggleControlCenter("system") }
    BarItem {
        visible: !isNaN(SystemStats.cpuTemp)
        icon: "device_thermostat"
        text: SystemStats.tempText
        color: SystemStats.cpuTemp >= 85 ? Theme.danger : Theme.text
        alert: SystemStats.cpuTemp >= 85
        onClicked: Ui.toggleControlCenter("system")
    }
    BarItem { icon: "memory"; text: SystemStats.memText; onClicked: Ui.toggleControlCenter("system") }
}
