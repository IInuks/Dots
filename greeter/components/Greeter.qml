import QtQuick
import Quickshell
import Quickshell.Io
import ".."

// The login screen host: user/session state, login and power actions, and
// the current style (styles/*.qml, see Styles.qml) loaded below. Styles
// call back into this item through their `ctl` property.
Item {
    id: root

    property int userIndex: 0
    property int sessionIndex: 0
    property bool leaving: false
    property bool restored: false

    // shown style; changes go through setStyle() for the transition
    property string styleId: ""
    property bool stylesOpen: false

    readonly property var user: Users.list[userIndex] ?? null
    readonly property var session: Sessions.list[sessionIndex] ?? null
    readonly property bool multiUser: Users.list.length > 1

    signal failed(string message)
    signal userSwitched()

    // Pick the remembered user/session once everything has loaded.
    function restore() {
        if (Prefs.ready && styleId === "")
            styleId = Styles.indexOf(Prefs.style) >= 0 ? Prefs.style : Styles.fallback;
        if (restored || !Prefs.ready || Users.list.length === 0 || Sessions.list.length === 0)
            return;
        restored = true;
        userIndex = Math.max(0, Users.indexOf(Prefs.lastUser));
        sessionIndex = Math.max(0, Sessions.indexOfFile(Prefs.lastSession));
    }
    Connections {
        target: Users
        function onListChanged() { root.restore(); }
    }
    Connections {
        target: Sessions
        function onListChanged() { root.restore(); }
    }
    Connections {
        target: Prefs
        function onReadyChanged() { root.restore(); }
    }
    Component.onCompleted: restore()

    // -- API for the styles ------------------------------------------------
    function setUser(index) {
        if (index === userIndex || index < 0 || index >= Users.list.length) return;
        Auth.cancel();
        userIndex = index;
        userSwitched();
    }
    function cycleUser(step) {
        if (Users.list.length < 2) return;
        setUser((userIndex + step + Users.list.length) % Users.list.length);
    }
    function setSession(index) {
        if (index >= 0 && index < Sessions.list.length) sessionIndex = index;
    }
    function cycleSession(step) {
        if (Sessions.list.length === 0) return;
        sessionIndex = (sessionIndex + step + Sessions.list.length) % Sessions.list.length;
    }

    function submit(secret) {
        if (!user || !session || leaving) return;
        Auth.login(user.name, secret, Sessions.command(session), Sessions.environment(session));
    }

    // suspend / reboot / poweroff via elogind; mock mode only logs
    function power(action) {
        if (Auth.mock) {
            console.log("[mock] loginctl", action);
            return;
        }
        powerProc.command = ["loginctl", action];
        powerProc.running = true;
    }
    Process { id: powerProc }

    function openStyles() {
        if (leaving || stylesOpen) return;
        stylesOpen = true;
        menuLoader.active = true;
    }
    function closeStyles() {
        if (menuLoader.item) menuLoader.item.close();
    }
    function setStyle(id) {
        if (Styles.indexOf(id) < 0) return;
        closeStyles();
        if (id === styleId) return;
        Prefs.setStyle(id);
        swap.target = id;
        swap.restart();
    }

    Connections {
        target: Auth
        function onSucceeded() {
            Prefs.remember(root.user.name, root.session.file);
            root.closeStyles();
            root.leaving = true;
        }
        function onFailed(message) { root.failed(message); }
    }

    // Test hooks, only in mock mode (or QD_GREETER_IPC=1): qs ipc -p <dir> call greeter submit test
    IpcHandler {
        target: "greeter"
        enabled: Auth.mock || Quickshell.env("QD_GREETER_IPC") === "1"
        function submit(secret: string): void { root.submit(secret); }
        function fail(message: string): void { root.failed(message); }
        function session(step: int): void { root.cycleSession(step); }
        function style(id: string): void { root.setStyle(id); }
        function styles(): void { root.openStyles(); }
        function close(): void { root.closeStyles(); }
        function shot(path: string): void { root.grabToImage(r => r.saveToFile(path)); }
    }

    // -- the style ---------------------------------------------------------
    Loader {
        id: stage
        anchors.fill: parent
        // wait for the wallpaper colors (no flash of the default palette)
        // and the saved style (no flash of the wrong one)
        opacity: root.leaving || !WallColors.ready || status !== Loader.Ready ? 0 : 1
        scale: root.leaving ? 0.97 : 1
        Behavior on opacity {
            enabled: !swap.running
            NumberAnimation { duration: Theme.animSlow; easing.type: Easing.InOutCubic }
        }
        Behavior on scale {
            enabled: !swap.running
            NumberAnimation { duration: Theme.animSlow; easing.type: Easing.InCubic }
        }

        function load(id) {
            setSource(Styles.url(id), { ctl: root, preview: false });
        }
        Component.onCompleted: if (root.styleId !== "") load(root.styleId)
        Connections {
            target: root
            // first assignment from restore(); later switches go through `swap`
            function onStyleIdChanged() { if (stage.source.toString() === "") stage.load(root.styleId); }
        }
    }

    // old style shrinks and fades, the new one plays its own intro
    SequentialAnimation {
        id: swap
        property string target: ""
        ParallelAnimation {
            NumberAnimation { target: stage; property: "opacity"; to: 0; duration: 220; easing.type: Easing.InCubic }
            NumberAnimation { target: stage; property: "scale"; to: 0.94; duration: 220; easing.type: Easing.InCubic }
        }
        ScriptAction {
            script: {
                root.styleId = swap.target;
                stage.load(swap.target);
                stage.scale = 1.04;
            }
        }
        ParallelAnimation {
            NumberAnimation { target: stage; property: "opacity"; to: 1; duration: 380; easing.type: Easing.OutCubic }
            NumberAnimation { target: stage; property: "scale"; to: 1; duration: 520; easing.type: Easing.OutCubic }
        }
        // hand the properties back to their bindings
        ScriptAction {
            script: {
                stage.opacity = Qt.binding(() => root.leaving || !WallColors.ready || stage.status !== Loader.Ready ? 0 : 1);
                stage.scale = Qt.binding(() => root.leaving ? 0.97 : 1);
                if (!root.stylesOpen && stage.item) stage.item.focusField();
            }
        }
    }

    Text {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        anchors.topMargin: Theme.spacingM
        visible: Auth.mock
        opacity: stage.opacity
        text: "mock mode · password: test"
        color: Theme.textFaint
        font.family: Theme.fontFamily
        font.pixelSize: Theme.fontS
    }

    // -- style menu (Alt+S or the style button) ------------------------------
    Loader {
        id: menuLoader
        anchors.fill: parent
        active: false
        z: 10
        sourceComponent: StyleMenu {
            ctl: root
            onClosed: {
                root.stylesOpen = false;
                menuLoader.active = false;
                if (stage.item && !swap.running) stage.item.focusField();
            }
        }
    }

    // final fade to black while greetd starts the session
    Rectangle {
        anchors.fill: parent
        z: 20
        color: "black"
        opacity: root.leaving ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: Theme.animSlow; easing.type: Easing.InQuad } }
    }
}
