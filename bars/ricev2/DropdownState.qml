pragma Singleton
import QtQuick

// Which bar dropdown (menus prompt section 1) is currently open, if any --
// "" means none. Exactly one at a time: opening a new one replaces the old
// rather than stacking, same as clicking a different pill in most bars.
// Lives at root (not under Bar/) for the same reason as Config.qml/
// Colors.qml -- a pragma-Singleton only resolves via same-dir or a pure
// ".." parent-chain import here (memory:
// feedback_quickshell_singleton_cross_dir_import).
QtObject {
    id: root

    // "" | "volume" | "wifi" | "bluetooth" | "calendar" | "weather" | "notifications" | "settings" | "sysmonitor"
    // sysmonitor is the one left-island entry -- every other id here opens
    // from the right island (see TopBar.qml's two separate Dropdown hosts).
    property string open: ""

    // Set by WifiDropdown's PasswordField while it wants real typed input.
    // BarShell binds WlrLayershell.keyboardFocus to this so the panel only
    // grabs exclusive focus for that one sub-case (menus prompt 1.2) --
    // unverified against mango's actual behavior on a long-lived reused
    // surface, see README "Bekannte Risiken" (memory:
    // feedback_mango_ondemand_focus_requires_fresh_surface).
    property bool keyboardWanted: false

    function toggle(id) {
        root.open = (root.open === id) ? "" : id;
        root.keyboardWanted = false;
    }
    function close() {
        root.open = "";
        root.keyboardWanted = false;
    }
}
