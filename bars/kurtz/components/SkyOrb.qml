import QtQuick
import "../"

// Sun or moon depending on the hour -- the clock's little focal element.
//   06-08  sunrise  orange sun
//   08-18  day      yellow sun, glowing
//   18-20  sunset   orange sun
//   20-06  night    pale moon (fat crescent) + two tiny stars
Item {
    id: root
    property int hour: new Date().getHours()
    property bool breathe: true      // slow glow pulse (off in the bar to save CPU)

    readonly property string phase: hour >= 20 || hour < 6 ? "night" : hour < 8 ? "rise" : hour < 18 ? "day" : "set"
    readonly property bool night: phase === "night"

    implicitWidth: 22
    implicitHeight: 22

    Orb {
        anchors.fill: parent
        color: root.night ? "#DCE3F5" : root.phase === "day" ? Theme.yellow : Theme.orange
        crescent: root.night ? 0.42 : 0.16
        glowing: true
        glowStrength: root.night ? 0.35 : 0.9
        glowSize: 2.4

        // gentle "breathing" glow, 5 s
        SequentialAnimation on glowStrength {
            running: Theme.animations && !root.night && root.breathe && root.visible
            loops: Animation.Infinite
            NumberAnimation { to: 0.6; duration: 2500; easing.type: Easing.InOutSine }
            NumberAnimation { to: 1.0; duration: 2500; easing.type: Easing.InOutSine }
        }
    }
    Repeater {
        model: root.night ? 2 : 0
        Rectangle {
            required property int index
            width: index === 0 ? 3 : 2
            height: width
            radius: width / 2
            color: Theme.text
            x: index === 0 ? root.width + 1 : root.width - 2
            y: index === 0 ? 0 : root.height - 3
            opacity: 0.8
        }
    }
}
