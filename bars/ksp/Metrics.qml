pragma Singleton
import QtQuick

// Geometry/timing constants. Not "Layout" -- collides with
// QtQuick.Layouts' `Layout` attached property (see bars/chamaeleon).
QtObject {
    readonly property int barHeight: 36
    readonly property int barMargin: 8

    readonly property int controlCenterWidth: 360
    readonly property int controlCenterHeight: 400
    readonly property int tabBarHeight: 34

    readonly property int launcherWidth: 420
    readonly property int launcherHeight: 420

    readonly property int notificationsWidth: 340
    readonly property int notificationsHeight: 400

    readonly property int telemetryWidth: 360
    readonly property int telemetryHeight: 360

    readonly property string fontFamily: "sans-serif"
    readonly property string fontMono: "monospace"
}
