pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Non-color persisted bar settings: which screen edge the bar docks to, and
// whether the clock shows day/date alongside the time. Kept separate from
// Theme.qml (colors) so each stays focused.
QtObject {
    id: settings

    property string barPosition: "top" // "top" | "bottom" | "left" | "right"
    readonly property bool vertical: barPosition === "left" || barPosition === "right"
    // Vertical bars need extra thickness for the clock's stacked time/date
    // lines (unlike the horizontal bar, they can't just grow sideways).
    readonly property int barThickness: vertical ? 56 : Theme.barHeight

    property bool showClockDate: true

    function setBarPosition(pos) {
        if (pos !== "top" && pos !== "bottom" && pos !== "left" && pos !== "right") return;
        barPosition = pos;
        persistence.adapter.barPosition = pos;
    }

    function setShowClockDate(v) {
        showClockDate = v;
        persistence.adapter.showClockDate = v;
    }

    property var persistence: FileView {
        id: persistence
        path: Quickshell.statePath("settings.json")
        watchChanges: true
        onLoaded: {
            settings.barPosition = adapter.barPosition;
            settings.showClockDate = adapter.showClockDate;
        }
        onAdapterUpdated: writeAdapter()
        adapter: JsonAdapter {
            property string barPosition: "top"
            property bool showClockDate: true
        }
    }
}
