pragma Singleton
import QtQuick

// Geometry/timing constants -- no magic numbers scattered through the
// dock or popup files.
QtObject {
    readonly property int barHeight: 44
    readonly property int barSideMargin: 10
    readonly property int tagCount: 6

    readonly property int popupSlideDistance: 26
    readonly property int popupAnimMs: 260

    readonly property int launcherWidth: 460
    readonly property int launcherHeight: 480
    readonly property int wallpaperWidth: 620
    readonly property int wallpaperHeight: 380
    readonly property int quickSettingsWidth: 320
    readonly property int quickSettingsHeight: 300
    readonly property int notificationsWidth: 340
    readonly property int notificationsHeight: 440
    readonly property int powerWidth: 360
    readonly property int powerHeight: 96
    readonly property int volumeWidth: 260
    readonly property int volumeHeight: 92
    readonly property int monitorWidth: 320
    readonly property int monitorHeight: 300

    readonly property string fontFamily: "sans-serif"
}
