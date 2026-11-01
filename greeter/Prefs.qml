pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Remembers the last user, session and greeter style between logins. The state file has
// to be writable by the greeter user (install.sh creates the directory).
Singleton {
    id: root

    readonly property string path: Quickshell.env("QD_GREETER_STATE") || "/var/cache/qd-greeter/state.json"
    property alias lastUser: store.lastUser
    property alias lastSession: store.lastSession
    property alias style: store.style
    // true once the file was read (or found missing) -- defaults are final then
    property bool ready: false

    function remember(user, session) {
        store.lastUser = user;
        store.lastSession = session;
        file.writeAdapter();
    }

    function setStyle(id) {
        store.style = id;
        file.writeAdapter();
    }

    FileView {
        id: file
        path: root.path
        printErrors: false
        watchChanges: false
        onLoaded: root.ready = true
        onLoadFailed: root.ready = true

        JsonAdapter {
            id: store
            property string lastUser: ""
            property string lastSession: ""
            property string style: ""
        }
    }
}
