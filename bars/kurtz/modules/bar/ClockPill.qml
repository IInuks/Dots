import QtQuick
import Quickshell
import "../../"
import "../../components"

// Center clock: sun/moon orb, big bold time, muted date.
Pill {
    id: root
    padding: Theme.s3
    spacing: Theme.s3

    SystemClock {
        id: clock
        precision: Theme.c.showSeconds ? SystemClock.Seconds : SystemClock.Minutes
    }

    SkyOrb {
        visible: Theme.c.showClockOrb
        anchors.verticalCenter: parent.verticalCenter
        width: Theme.pillHeight * 0.6
        height: width
        hour: clock.hours
        breathe: Theme.c.barTwinkle
    }
    KLabel {
        anchors.verticalCenter: parent.verticalCenter
        text: Qt.formatTime(clock.date, Theme.c.clock24 ? (Theme.c.showSeconds ? "HH:mm:ss" : "HH:mm") : (Theme.c.showSeconds ? "h:mm:ss AP" : "h:mm AP"))
        font.pixelSize: Theme.fTitle + 1
        font.weight: Font.Bold
        font.features: { "tnum": 1 }
    }
    KLabel {
        anchors.verticalCenter: parent.verticalCenter
        role: "muted"
        visible: Theme.c.showDate
        text: Theme.date(clock.date, "ddd, d. MMM")
    }
}
