pragma Singleton
import QtQuick

// Geometry/timing constants. Named "Metrics" rather than "Layout" --
// that name collides with QtQuick.Layouts' `Layout` attached property,
// silently breaking every `Layout.xyz` on any RowLayout/ColumnLayout
// child anywhere in the tree (see bars/claude/README.md "Bug-Fundstuecke").
QtObject {
    readonly property int barHeight: 34
    readonly property int barMargin: 8

    readonly property int controlCenterWidth: 340
    readonly property int controlCenterHeight: 380
    readonly property int tabBarHeight: 32

    readonly property int launcherWidth: 420
    readonly property int launcherHeight: 420

    readonly property int notificationsWidth: 340
    readonly property int notificationsHeight: 400

    readonly property string fontFamily: "sans-serif"
}
