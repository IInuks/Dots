pragma Singleton
import QtQuick

// Each screen's Bar.qml registers itself here (outputName -> the Bar
// instance) so shell.qml's IpcHandlers can route "toggle this module" to
// the bar on the currently-focused monitor, without every IpcHandler
// needing its own Variants-aware lookup.
QtObject {
    id: root

    property var _bars: ({})

    function register(screenName, barItem) {
        const merged = Object.assign({}, root._bars);
        merged[screenName] = barItem;
        root._bars = merged;
    }

    function unregister(screenName) {
        const merged = Object.assign({}, root._bars);
        delete merged[screenName];
        root._bars = merged;
    }

    // Prefers the focused monitor; falls back to any registered bar so IPC
    // still does something useful before MangoService's first focus event
    // arrives, or on a single-monitor setup where "focused" can lag.
    function toggle(moduleId) {
        const preferred = MangoService.focusedMonitorName;
        const bar = root._bars[preferred] || Object.values(root._bars)[0];
        if (bar)
            bar.toggle(moduleId);
    }

    function open(moduleId) {
        const preferred = MangoService.focusedMonitorName;
        const bar = root._bars[preferred] || Object.values(root._bars)[0];
        if (bar && bar.activeModule !== moduleId)
            bar.toggle(moduleId);
    }

    function close(moduleId) {
        for (const bar of Object.values(root._bars)) {
            if (bar.activeModule === moduleId)
                bar.activeModule = "none";
        }
    }
}
