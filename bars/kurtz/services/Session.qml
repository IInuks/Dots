pragma Singleton
import QtQuick
import Quickshell
import "../"

// Power actions. On Bedrock the elogind-aware loginctl lives in the Void
// stratum, so prefer `strat void loginctl` and fall back to plain
// loginctl elsewhere. Logout asks mango to quit.
Singleton {
    id: root

    readonly property var actions: [
        { id: "logout", label: "Abmelden", glyph: Glyphs.logout, color: Theme.purple },
        { id: "suspend", label: "Bereitschaft", glyph: Glyphs.sleep, color: Theme.cyan },
        { id: "reboot", label: "Neustart", glyph: Glyphs.restart, color: Theme.orange },
        { id: "poweroff", label: "Ausschalten", glyph: Glyphs.power, color: Theme.red }
    ]

    function _loginctl(verb) {
        Quickshell.execDetached(["sh", "-c", "if command -v strat >/dev/null 2>&1; then exec strat void loginctl " + verb + "; else exec loginctl " + verb + "; fi"]);
    }

    function run(id) {
        Popups.close();
        if (id === "logout")
            Quickshell.execDetached(["mmsg", "dispatch", "quit"]);
        else if (id === "suspend" || id === "reboot" || id === "poweroff")
            root._loginctl(id);
    }
}
