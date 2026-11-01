pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// User-defined command buttons shown in the settings menu's "Befehle" tab:
// each is just a name + an arbitrary shell command, run detached via `sh -c`
// on click. Persisted as a JSON-encoded string (rather than a native list
// property on the adapter) so persistence stays plain JSON primitives, the
// same approach Theme.qml/Settings.qml use for their own state.
QtObject {
    id: shortcuts

    property var items: [] // [{ name: string, command: string }]

    function add(name, command) {
        if (!name || !command) return;
        items = items.concat([{ name: name, command: command }]);
        persistence.adapter.itemsJson = JSON.stringify(items);
    }

    function removeAt(index) {
        if (index < 0 || index >= items.length) return;
        const next = items.slice();
        next.splice(index, 1);
        items = next;
        persistence.adapter.itemsJson = JSON.stringify(items);
    }

    function updateAt(index, name, command) {
        if (index < 0 || index >= items.length || !name || !command) return;
        const next = items.slice();
        next[index] = { name: name, command: command };
        items = next;
        persistence.adapter.itemsJson = JSON.stringify(items);
    }

    // Runs via a plain (non-detached) Process, not Quickshell.execDetached,
    // so we can observe the exit code -- callback(exitCode) fires once the
    // command finishes. The Process is parented to this singleton (not to
    // whatever row triggered it), so it survives tab switches/menu close;
    // it only dies if quickshell itself restarts.
    function run(command, callback) {
        if (!command) return;
        const proc = Qt.createQmlObject(
            "import Quickshell.Io; Process {}",
            shortcuts,
            "shortcutRunner"
        );
        proc.command = ["sh", "-c", command];
        proc.exited.connect(function (exitCode) {
            if (callback) callback(exitCode);
            proc.destroy();
        });
        proc.running = true;
    }

    property var persistence: FileView {
        id: persistence
        path: Quickshell.statePath("shortcuts.json")
        watchChanges: true
        onLoaded: {
            try {
                const parsed = JSON.parse(adapter.itemsJson);
                shortcuts.items = Array.isArray(parsed) ? parsed : [];
            } catch (e) {
                shortcuts.items = [];
            }
        }
        onAdapterUpdated: writeAdapter()
        adapter: JsonAdapter {
            property string itemsJson: "[]"
        }
    }
}
