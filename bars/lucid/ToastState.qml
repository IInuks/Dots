pragma Singleton
import QtQuick

// One transient toast at a time, shown by every Bar instance (each screen's
// Bar.qml watches this and renders its own Toast overlay -- a toast should
// be visible regardless of which monitor the user is looking at).
// Reminders.qml is the first user; Stage 5 (Notifications) reuses this same
// singleton instead of building a second toast mechanism.
QtObject {
    id: root

    property bool visible: false
    property string title: ""
    property string message: ""

    property Timer _dismissTimer: Timer {
        interval: 6000
        onTriggered: root.visible = false
    }

    function show(title, message) {
        root.title = title;
        root.message = message;
        root.visible = true;
        _dismissTimer.restart();
    }

    function dismiss() {
        _dismissTimer.stop();
        root.visible = false;
    }
}
