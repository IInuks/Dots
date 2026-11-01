pragma Singleton
import QtQuick

// Global boot self-test flag. Starts true (unless Config.bootSequence says
// otherwise) and flips to false once, Theme.durBoot after launch -- while
// true, every segment widget (SevenSegment/FourteenSegment/SegmentBar)
// renders fully lit regardless of its real value, the same all-segments-on
// wipe a real digital watch runs on power-up. Root-level singleton for the
// same reason as Theme/Config: every file under bar/, menus/, widgets/
// already does `import ".."` (or deeper) to reach those two, and that same
// directory import picks up any other pragma-Singleton file living here too
// -- no extra import needed anywhere that already reaches Theme.
//
// One shared flag for the whole shell (not one per monitor/PanelWindow) so
// every screen's self-test wipes in sync -- there's only ever one boot
// moment for the process as a whole.
QtObject {
    id: root

    property bool selfTest: Config.bootSequence

    // QtObject has no default property -- a bare `Timer{}` child here fails
    // to attach at all (see feedback_qml_qtobject_no_default_property.md in
    // memory), so it has to be a named property assigned a Timer instance.
    property Timer _wipeTimer: Timer {
        interval: Theme.durBoot
        running: root.selfTest
        onTriggered: root.selfTest = false
    }
}
