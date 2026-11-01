pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Persisted user config -> ~/.config/ricev2/config.json (JsonAdapter
// pattern from bars/rice/Config.qml / bars/lucid/Config.qml). Everything
// else in this bar only reads from here; call the setX() functions to
// change + persist.
//
// Defaults below are this machine's actual values (checked, not
// guessed -- see README "Systemwerte"): compositor is mango, not
// niri/Hyprland/Sway like the original prompt's placeholder assumed;
// monitor is DP-4 (2560x1440@170, from ~/.config/mango/config.conf's
// monitorrule); WLAN interface is wlp9s0 over NetworkManager (nmcli) --
// iwd/iwctl isn't installed on this system, so the WLAN dropdown (menus
// prompt 1.2) talks to nmcli instead.
QtObject {
    id: root

    property bool ready: false

    // "classic" (three skewed islands) or "pill" (bar section 2).
    property string barStyle: "classic"

    // Launcher display mode (menus section 2, "Alternative Modi"): "slice"
    // (default, skewed overlapping strips), "hex" (honeycomb) or "grid"
    // (plain tiles). Switcher currently only implements "slice" -- its own
    // wheel/grid alternative modes are still on the "Noch nicht gebaut" list.
    property string launcherDisplayMode: "slice"

    // Falls back to Quickshell.screens[0] at the call site if this name
    // doesn't match any connected output.
    property string monitorName: "DP-4"

    property string wifiInterface: "wlp9s0"
    property string weatherCity: "Wien"
    property string weatherSource: "open-meteo"

    // "" = no preference, use whichever MPRIS player last became active
    // (user's choice -- no player was installed to test a real name
    // against, see README "Bevorzugter Player").
    property string preferredPlayer: ""

    property string terminal: "kitty"

    property var widgetsLeft: ["cpu", "gpu", "memory"]
    property var widgetsRight: ["weather", "bluetooth", "wifi", "brightness", "battery", "volume", "notifications", "settings", "clock"]

    // Idle-state look of the middle island's workspace indicator (see
    // Bar/lyrics/WorkspacePips.qml): "dots" (default, original pip look) |
    // "numbers" | "roman" | "bars" (mini equalizer bars, matching the
    // island's own cava visualizer theme). Picked via the new settings
    // dropdown (Bar/menus/SettingsDropdown.qml).
    property string workspaceStyle: "dots"

    // Per-widget overrides: { "<id>": { icon, label, disabled, mouseover } }
    property var widgetOverrides: ({})

    property bool qsmemEnabled: false

    property bool barVisible: true

    // Notification popups (menus prompt section 5): "right" (default) or
    // "left" edge of the configured monitor.
    property string notificationPopupSide: "right"

    // Power menu (menus prompt section 4): spec's placeholder commands
    // (`loginctl lock-session`, `niri msg action quit`) don't apply here --
    // checked against this system instead, same commands every other bar
    // in this repo already verified working (see README "Power-Menü"):
    // no swayidle/logind lock-handler runs here, so `loginctl lock-session`
    // would be a silent no-op; `swaylock` (the only installed locker) is
    // called directly instead. mango's own IPC quit is `mmsg dispatch
    // quit`, not a niri/Hyprland/Sway command. "enabled: false" hides an
    // option without removing it, per spec ("Alle Optionen sind per Config
    // überschreibbar").
    property var powerOptions: [
        { id: "lock", label: "Lock", icon: "\u{F033E}", command: ["swaylock"], enabled: true },
        { id: "logout", label: "Logout", icon: "\u{F0343}", command: ["mmsg", "dispatch", "quit"], enabled: true },
        { id: "reboot", label: "Reboot", icon: "\u{F0709}", command: ["loginctl", "reboot"], enabled: true },
        { id: "poweroff", label: "Poweroff", icon: "\u{F0425}", command: ["loginctl", "poweroff"], enabled: true }
    ]

    function setBarStyle(v) { root.barStyle = v; _persist(); }
    function setLauncherDisplayMode(v) { root.launcherDisplayMode = v; _persist(); }
    function setBarVisible(v) { root.barVisible = v; _persist(); }
    function setWidgetsLeft(v) { root.widgetsLeft = v; _persist(); }
    function setWidgetsRight(v) { root.widgetsRight = v; _persist(); }
    function setWeatherCity(v) { root.weatherCity = v; _persist(); }
    function setPreferredPlayer(v) { root.preferredPlayer = v; _persist(); }
    function setNotificationPopupSide(v) { root.notificationPopupSide = v; _persist(); }
    function setPowerOptions(v) { root.powerOptions = v; _persist(); }
    function setWorkspaceStyle(v) { root.workspaceStyle = v; _persist(); }

    function _persist() {
        if (!root.ready)
            return;
        _file.adapter.barStyle = root.barStyle;
        _file.adapter.launcherDisplayMode = root.launcherDisplayMode;
        _file.adapter.monitorName = root.monitorName;
        _file.adapter.wifiInterface = root.wifiInterface;
        _file.adapter.weatherCity = root.weatherCity;
        _file.adapter.weatherSource = root.weatherSource;
        _file.adapter.preferredPlayer = root.preferredPlayer;
        _file.adapter.terminal = root.terminal;
        _file.adapter.widgetsLeft = root.widgetsLeft;
        _file.adapter.widgetsRight = root.widgetsRight;
        _file.adapter.widgetOverrides = root.widgetOverrides;
        _file.adapter.qsmemEnabled = root.qsmemEnabled;
        _file.adapter.barVisible = root.barVisible;
        _file.adapter.notificationPopupSide = root.notificationPopupSide;
        _file.adapter.powerOptions = root.powerOptions;
        _file.adapter.workspaceStyle = root.workspaceStyle;
        _file.writeAdapter();
    }

    property FileView _file: FileView {
        path: Quickshell.env("HOME") + "/.config/ricev2/config.json"
        watchChanges: false
        atomicWrites: true

        adapter: JsonAdapter {
            property string barStyle: "classic"
            property string launcherDisplayMode: "slice"
            property string monitorName: "DP-4"
            property string wifiInterface: "wlp9s0"
            property string weatherCity: "Wien"
            property string weatherSource: "open-meteo"
            property string preferredPlayer: ""
            property string terminal: "kitty"
            property var widgetsLeft: ["cpu", "gpu", "memory"]
            property var widgetsRight: ["weather", "bluetooth", "wifi", "brightness", "battery", "volume", "notifications", "settings", "clock"]
            property var widgetOverrides: ({})
            property string workspaceStyle: "dots"
            property bool qsmemEnabled: false
            property bool barVisible: true
            property string notificationPopupSide: "right"
            property var powerOptions: [
                { id: "lock", label: "Lock", icon: "\u{F033E}", command: ["swaylock"], enabled: true },
                { id: "logout", label: "Logout", icon: "\u{F0343}", command: ["mmsg", "dispatch", "quit"], enabled: true },
                { id: "reboot", label: "Reboot", icon: "\u{F0709}", command: ["loginctl", "reboot"], enabled: true },
                { id: "poweroff", label: "Poweroff", icon: "\u{F0425}", command: ["loginctl", "poweroff"], enabled: true }
            ]
        }

        onLoaded: {
            root.barStyle = adapter.barStyle;
            root.launcherDisplayMode = adapter.launcherDisplayMode;
            root.monitorName = adapter.monitorName;
            root.wifiInterface = adapter.wifiInterface;
            root.weatherCity = adapter.weatherCity;
            root.weatherSource = adapter.weatherSource;
            root.preferredPlayer = adapter.preferredPlayer;
            root.terminal = adapter.terminal;
            root.widgetsLeft = adapter.widgetsLeft;
            root.widgetsRight = adapter.widgetsRight;
            root.widgetOverrides = adapter.widgetOverrides;
            root.qsmemEnabled = adapter.qsmemEnabled;
            root.barVisible = adapter.barVisible;
            root.notificationPopupSide = adapter.notificationPopupSide;
            root.powerOptions = adapter.powerOptions;
            root.workspaceStyle = adapter.workspaceStyle;
            root.ready = true;
        }
        onLoadFailed: error => {
            // First run: no config.json yet -- keep the in-QML defaults
            // above and write them out so the file exists from now on.
            root.ready = true;
            root._persist();
        }
    }
}
