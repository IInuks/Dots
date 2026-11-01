import QtQuick
import ".."

// The password input every style uses: key handling, PAM prompts and the
// error state live here, the style draws everything around it (box, hint,
// shake on `rejected`).
//
// Keys: Enter logs in, Esc clears, Alt+←/→ user, Alt+↑/↓ session,
// Alt+S style menu.
TextInput {
    id: field

    property var ctl: null
    property bool preview: false
    property string error: ""

    // what a style shows while the field is empty
    readonly property string hint: Auth.busy ? "Signing in…"
                                 : Auth.awaiting && Auth.prompt !== "" ? Auth.prompt : "Password"
    // true while the user is busy with the login (styles blur, move, ...)
    readonly property bool engaged: text.length > 0 || Auth.busy || Auth.awaiting || error !== ""
    readonly property bool canSubmit: text.length > 0 || Auth.awaiting

    signal rejected()

    function submit() {
        if (preview || !ctl) return;
        if (canSubmit) ctl.submit(text);
        text = "";
    }
    function fail(message) {
        text = "";
        error = message !== "" ? message : "Login failed";
        rejected();
        forceActiveFocus();
    }
    function reset() {
        text = "";
        error = "";
        if (!preview) forceActiveFocus();
    }

    color: Theme.text
    selectionColor: Theme.accent
    selectedTextColor: Theme.accentText
    font.family: Theme.fontFamily
    font.pixelSize: Theme.fontL
    font.letterSpacing: echoMode === TextInput.Password ? 3 : 0
    echoMode: Auth.awaiting && Auth.echo ? TextInput.Normal : TextInput.Password
    passwordCharacter: "•"
    passwordMaskDelay: 0
    clip: true
    enabled: !Auth.busy && !preview
    focus: !preview

    Component.onCompleted: if (!preview) forceActiveFocus()
    onTextEdited: error = ""

    Connections {
        target: field.preview ? null : field.ctl
        function onFailed(message) { field.fail(message); }
        function onUserSwitched() { field.reset(); }
    }

    Keys.onPressed: event => {
        const alt = event.modifiers & Qt.AltModifier;
        if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
            submit();
        } else if (event.key === Qt.Key_Escape) {
            text = "";
            error = "";
            Auth.cancel();
        } else if (alt && event.key === Qt.Key_Left) {
            ctl.cycleUser(-1);
        } else if (alt && event.key === Qt.Key_Right) {
            ctl.cycleUser(1);
        } else if (alt && event.key === Qt.Key_Up) {
            ctl.cycleSession(-1);
        } else if (alt && event.key === Qt.Key_Down) {
            ctl.cycleSession(1);
        } else if (alt && event.key === Qt.Key_S) {
            ctl.openStyles();
        } else {
            return;
        }
        event.accepted = true;
    }
}
