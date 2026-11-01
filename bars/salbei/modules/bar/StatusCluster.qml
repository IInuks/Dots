import QtQuick
import "../../"
import "../../services"

// Volume, brightness, battery. Modules without a backend are hidden.
Row {
    spacing: Theme.barSpacing

    BarItem {
        visible: Audio.available
        icon: Audio.icon
        text: Math.round(Audio.volume * 100) + "%"
        dim: Audio.muted ? 0.45 : 1
        onClicked: Audio.toggleMute()
        onWheel: d => Audio.step(d > 0 ? 0.05 : -0.05)
    }
    BarItem {
        visible: Brightness.available
        icon: "light_mode"
        text: Math.round(Brightness.value * 100) + "%"
        onClicked: Ui.toggleControlCenter("monitor")
        onWheel: d => Brightness.step(d > 0 ? 0.05 : -0.05)
    }
    BarItem {
        visible: Battery.available
        icon: Battery.icon
        text: Math.round(Battery.percent * 100) + "%"
        color: Battery.charging ? Theme.accent : Battery.low ? Theme.danger : Theme.text
        alert: Battery.charging || Battery.low
        onClicked: Ui.toggleControlCenter("power")
    }
}
