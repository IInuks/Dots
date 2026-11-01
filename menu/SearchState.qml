pragma Singleton
import QtQuick

// Open/close state for the standalone app search popup (SUPER+space).
// Only opens while the app search is the launcher in use for the active
// bar (LauncherStore: the bar's default when it has no launcher of its
// own, or assigned in the "Launcher" tab) -- otherwise SUPER+space isn't
// bound to it anyway, this just keeps a stray IPC call from opening it next
// to the bar's real launcher. forceOpen() skips that check ("Ausprobieren").
QtObject {
    id: root

    property bool visible: false

    function open(): void {
        if (LauncherStore.effective(BarsModel.activeBar) !== "appsearch") return;
        root.visible = true;
    }

    function forceOpen(): void { root.visible = true; }

    function close(): void { root.visible = false; }

    function toggle(): void {
        if (root.visible) { root.visible = false; return; }
        root.open();
    }
}
