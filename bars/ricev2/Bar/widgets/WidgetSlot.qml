import QtQuick
import "../../"

// Generic show/hide wrapper for one bar widget (bar prompt section 4,
// "Ein-/Ausblend-Animation" + "Mouseover-Modus"). Loads the widget's QML
// file by id so TopBar.qml stays data-driven off Config.widgetsLeft/Right
// instead of hardcoding a Repeater delegate per widget -- adding a widget
// later means adding one entry to _files below plus the file itself, not
// touching TopBar.qml.
//
// A widget file opts into the "hidden if no data" rule (spec: wifi/
// bluetooth/brightness/battery) by exposing `readonly property bool
// available`; without one it's always shown once enabled. Loader keeps
// `active: true` at all times (even while hidden) so a data-gated widget
// can still notice when its data reappears and animate back in.
Item {
    id: root

    required property string widgetId
    property bool sideHovered: false

    readonly property var _override: Config.widgetOverrides[widgetId] || ({})
    readonly property bool _disabledByConfig: !!_override.disabled
    readonly property bool _mouseoverMode: _override.mouseover === true
    readonly property bool _dataAvailable: loader.item && loader.item.available !== undefined ? loader.item.available : true
    readonly property bool shouldShow: _dataAvailable && !_disabledByConfig && (!_mouseoverMode || sideHovered)

    readonly property var _files: ({
        cpu: "CpuWidget.qml",
        gpu: "GpuWidget.qml",
        memory: "MemoryWidget.qml",
        weather: "WeatherWidget.qml",
        bluetooth: "BluetoothWidget.qml",
        wifi: "WifiWidget.qml",
        brightness: "BrightnessWidget.qml",
        battery: "BatteryWidget.qml",
        volume: "VolumeWidget.qml",
        notifications: "NotificationsWidget.qml",
        settings: "SettingsWidget.qml",
        clock: "ClockWidget.qml"
    })

    clip: true
    implicitWidth: shouldShow ? loader.implicitWidth : 0
    implicitHeight: Style.barHeight
    width: implicitWidth
    height: implicitHeight
    opacity: shouldShow ? 1 : 0

    Behavior on implicitWidth { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
    Behavior on opacity { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }

    Loader {
        id: loader
        anchors.verticalCenter: parent.verticalCenter
        active: true
        source: root._files[root.widgetId] || ""
    }
}
