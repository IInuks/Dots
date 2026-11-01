import QtQuick
import "../../"
import "../../components"
import "../../services"

// Three mini rings: CPU, RAM, temperature. Each ring keeps its own hue
// until it gets hot (then warn yellow / critical pink).
Pill {
    id: root
    padding: Theme.s2
    spacing: Theme.s2

    component Mini: Ring {
        id: ring
        property string glyph
        property color hue
        anchors.verticalCenter: parent.verticalCenter
        width: Theme.pillHeight - 6
        height: width
        thickness: 3
        animated: false     // bar is always visible: no 640 ms tween every 2 s
        color: value < 0.7 ? hue : value < 0.88 ? Theme.warn : Theme.crit
        glowing: value >= 0.88
        KIcon {
            anchors.centerIn: parent
            text: ring.glyph
            size: ring.width * 0.42
            color: Theme.textMuted
        }
    }

    Mini { value: Stats.cpu; glyph: Glyphs.cpu; hue: Theme.accent }
    Mini { value: Stats.mem; glyph: Glyphs.memory; hue: Theme.purple }
    Mini {
        visible: Stats.temp > 0
        value: Math.max(0, (Stats.temp - 30) / 65)
        glyph: Glyphs.temp
        hue: Theme.orange
    }
}
