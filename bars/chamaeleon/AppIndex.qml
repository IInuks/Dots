pragma Singleton
import QtQuick
import Quickshell

// Plain substring search over Quickshell's own desktop-entry index -- no
// scoring, no usage history, just filter + launch.
QtObject {
    id: root

    function all() {
        return DesktopEntries.applications.values.filter(e => !e.noDisplay);
    }

    function search(query) {
        const needle = (query || "").trim().toLowerCase();
        const list = root.all();
        if (needle.length === 0)
            return list.slice().sort((a, b) => (a.name || "").localeCompare(b.name || ""));
        return list.filter(e => (e.name || "").toLowerCase().includes(needle)
                                 || (e.genericName || "").toLowerCase().includes(needle))
                   .sort((a, b) => (a.name || "").localeCompare(b.name || ""));
    }

    function launch(entry) {
        if (entry)
            entry.execute();
    }
}
