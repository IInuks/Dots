pragma Singleton
import QtQuick

// Bridges shell.qml's `launcher` IpcHandler (mango's SUPER+space keybind,
// once routed here -- see README "App-Launcher") to a fresh LauncherWindow
// instance, spawned by a Loader in shell.qml bound to `isOpen`.
//
// Deliberately not "the window's `visible` just follows a bool on an
// always-mapped surface": see LauncherWindow.qml's own comment for why the
// window must be created fresh on every open instead (same mango
// on-demand-keyboard-focus quirk already solved this way in
// bars/fisheye/LauncherWindow.qml and confirmed independently in
// bars/lumen, memory: feedback_mango_ondemand_focus_requires_fresh_
// surface). `screenName` is snapshotted at open() time so the Loader's
// delegate knows which monitor to appear on without needing a BarRegistry-
// style per-screen instance map -- there's only ever one launcher open at
// a time, unlike the six per-screen pill panels.
QtObject {
    id: root

    property bool isOpen: false
    property string screenName: ""

    function toggle() {
        if (root.isOpen)
            root.close();
        else
            root.open();
    }
    function open() {
        root.screenName = MangoService.focusedMonitorName;
        root.isOpen = true;
    }
    function close() {
        root.isOpen = false;
    }
}
