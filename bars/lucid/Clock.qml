pragma Singleton
import QtQuick

// Single shared "now" for the whole bar (pill time text, calendar's today
// highlight, reminder due-checks) -- one Timer instead of every consumer
// running its own.
QtObject {
    id: root

    property date now: new Date()

    property Timer _tick: Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: root.now = new Date()
    }

    function formatTime(fmt) {
        return Qt.formatTime(root.now, fmt);
    }
    function formatDate(fmt) {
        return Qt.formatDate(root.now, fmt);
    }
}
