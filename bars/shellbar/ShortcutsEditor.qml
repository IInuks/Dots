pragma Singleton
import QtQuick

// Shared open/prefill state for the big centered "add/edit command" modal
// (the actual modal UI lives in Bar.qml's overlay, once per screen). The
// Commands tab (SettingsMenu.qml) calls openForAdd()/openForEdit() to show
// it and hand over the values to prefill; Bar.qml reads name/script once
// when it opens, then talks to Shortcuts.qml directly to save.
QtObject {
    id: root

    property bool open: false
    property int index: -1
    property string name: ""
    property string script: ""

    function openForAdd() {
        root.index = -1;
        root.name = "";
        root.script = "";
        root.open = true;
    }

    function openForEdit(i, n, s) {
        root.index = i;
        root.name = n;
        root.script = s;
        root.open = true;
    }

    function close() {
        root.open = false;
    }
}
