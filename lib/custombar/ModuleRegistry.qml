import QtQuick

// Central catalog of every module type a custom bar can use. Deliberately
// NOT a singleton: this data is static/stateless, and the menu's editor
// (menu/custom/*.qml) needs it too, reached only through a symlinked
// sibling directory (menu/custombarlib) -- singleton property/method
// access is broken across any such "sideways" relative import in this
// Quickshell version (silently returns an all-fields-undefined proxy,
// confirmed by direct testing), while plain type instantiation works fine
// everywhere. So every consumer just declares its own local instance
// (`ModuleRegistry { id: registry }`) instead of relying on one shared one.
//
// Both the editor (module palette + per-instance settings form) and the
// engine (Loader by type in ZoneContent.qml) read only from here -- adding
// a module later means one new file in modules/ plus one entry below,
// nothing else changes.
QtObject {
    id: root

    readonly property var modules: [
        {
            type: "clock",
            label: "Uhr",
            icon: "🕐",
            file: "modules/ClockModule.qml",
            defaultSettings: { format: "HH:mm" },
            settingsFields: [
                { key: "format", label: "Format", kind: "choice", options: ["HH:mm", "HH:mm:ss", "hh:mm AP"] }
            ]
        },
        {
            type: "workspaces",
            label: "Workspaces",
            icon: "▤",
            file: "modules/WorkspacesModule.qml",
            defaultSettings: { groupSize: 1 },
            settingsFields: [
                { key: "groupSize", label: "Gruppierung (1 = einzeln)", kind: "choice", options: [1, 3, 5, 9] }
            ]
        },
        {
            type: "tray",
            label: "System-Tray",
            icon: "▣",
            file: "modules/TrayModule.qml",
            defaultSettings: {},
            settingsFields: []
        },
        {
            type: "cpu",
            label: "CPU-Auslastung",
            icon: "◔",
            file: "modules/CpuModule.qml",
            defaultSettings: {},
            settingsFields: []
        },
        {
            type: "volume",
            label: "Lautstärke",
            icon: "♪",
            file: "modules/VolumeModule.qml",
            defaultSettings: { step: 5 },
            settingsFields: [
                { key: "step", label: "Schrittweite (%)", kind: "choice", options: [1, 5, 10] }
            ]
        },
        {
            type: "power",
            label: "Power-Button",
            icon: "⏻",
            file: "modules/PowerButtonModule.qml",
            defaultSettings: {},
            settingsFields: []
        }
    ]

    function byType(type) {
        for (const m of root.modules) if (m.type === type) return m;
        return null;
    }

    function defaultsFor(type) {
        const m = root.byType(type);
        return m ? JSON.parse(JSON.stringify(m.defaultSettings)) : {};
    }
}
