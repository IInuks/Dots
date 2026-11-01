pragma Singleton
import QtQuick
import Quickshell

// Menus-prompt section 2: app enumeration + filtering for the launcher.
// Wraps Quickshell's own DesktopEntries singleton (same idiom as
// bars/ksp/AppIndex.qml) instead of hand-parsing .desktop files like
// bars/quickbar/DesktopEntries.qml does -- no async scan step needed,
// so `ready` is always true here (see README "App-Cache").
//
// "Games" / "Steam" filters (spec section 2, filter row) are new territory
// for this repo -- no sibling bar has them. Checked against this system's
// real .desktop files rather than guessed: Steam-installed games (e.g.
// ~/.local/share/applications/"Kerbal Space Program.desktop") ship
// `Categories=Game;` and `Exec=steam steam://rungameid/<appid>`, so both
// filters key off that shape.
QtObject {
    id: root

    readonly property bool ready: true

    function _isSteam(e) {
        const cmd = e.command || [];
        return cmd.length > 0 && String(cmd[0]).toLowerCase() === "steam";
    }

    function _steamAppId(e) {
        const cmd = e.command || [];
        for (const part of cmd) {
            const m = /rungameid\/(\d+)/.exec(String(part));
            if (m)
                return m[1];
        }
        return "";
    }

    function _isGame(e) {
        return (e.categories || []).includes("Game");
    }

    function all() {
        return DesktopEntries.applications.values
            .filter(e => !e.noDisplay)
            .map(e => {
                const isSteam = root._isSteam(e);
                return {
                    entry: e,
                    id: e.id,
                    name: e.name || "",
                    icon: e.icon || "",
                    isGame: root._isGame(e),
                    isSteam: isSteam,
                    steamAppId: isSteam ? root._steamAppId(e) : ""
                };
            })
            .sort((a, b) => a.name.localeCompare(b.name));
    }

    // filter: "all" | "apps" | "games" | "steam"
    function filtered(filter, query) {
        let list = root.all();
        if (filter === "apps")
            list = list.filter(a => !a.isGame);
        else if (filter === "games")
            list = list.filter(a => a.isGame);
        else if (filter === "steam")
            list = list.filter(a => a.isSteam);

        const needle = (query || "").trim().toLowerCase();
        if (needle.length > 0)
            list = list.filter(a => a.name.toLowerCase().includes(needle));
        return list;
    }

    function launch(app) {
        if (app && app.entry)
            app.entry.execute();
    }

    // Steam's own library-grid portrait artwork (verified present on this
    // system, e.g. .../librarycache/220200/library_600x900.jpg) -- used as
    // the slice's background image per spec ("Steam-Artwork"). Callers
    // just try loading this path and fall back on Image.onStatusChanged
    // === Error; no existence pre-check needed.
    function artworkPath(app) {
        if (!app || !app.isSteam || !app.steamAppId)
            return "";
        return "file://" + Quickshell.env("HOME") + "/.local/share/Steam/appcache/librarycache/" + app.steamAppId + "/library_600x900.jpg";
    }
}
