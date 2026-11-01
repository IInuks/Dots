pragma Singleton
import QtQuick

// One shared "now", 1s tick -- single Timer instead of every clock/date
// consumer running its own (same reasoning as bars/lucid/Clock.qml).
// Austrian locale (de_AT) per this user's system (memory: user-system).
QtObject {
    id: root

    property date now: new Date()

    // toLocaleDateString(locale, format) IS locale-aware for weekday/month
    // names (unlike Qt.formatDate, which always uses "C" names) --
    // Qt.locale("de_AT") gives "Sa" / "Sep." here instead of "Sat" / "Sep".
    readonly property var _atLocale: Qt.locale("de_AT")
    readonly property string timeText: Qt.formatTime(root.now, "HH:mm")
    readonly property string dateText: root.now.toLocaleDateString(root._atLocale, "ddd, d. MMM")

    property Timer _tick: Timer {
        interval: 1000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: root.now = new Date()
    }
}
