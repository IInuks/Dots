pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Services.Greetd

// Thin layer over Quickshell's Greetd service so the UI only deals with
// "login(user, secret, session)" plus a few status properties.
//
// Without a greetd socket (or with QD_GREETER_MOCK=1) a mock backend runs
// instead: the password "test" succeeds, anything else fails. Used for
// trying the greeter inside a normal session.
Singleton {
    id: root

    readonly property bool mock: Quickshell.env("QD_GREETER_MOCK") === "1" || !Greetd.available

    // A PAM prompt is waiting for the user (e.g. a second factor or an
    // expired password). The UI shows `prompt` as the field placeholder.
    property bool awaiting: false
    property string prompt: ""
    property bool echo: false

    property bool busy: false
    property string info: ""       // last non-prompt PAM message

    signal failed(string message)
    signal succeeded()             // about to launch -- UI fades out

    property var _command: []
    property var _env: []
    property string _secret: ""
    property bool _hasSecret: false

    function login(user, secret, command, env) {
        _command = command;
        _env = env;
        info = "";

        if (awaiting) {
            awaiting = false;
            busy = true;
            _respond(secret);
            return;
        }

        busy = true;
        _secret = secret;
        _hasSecret = true;
        if (mock) {
            mockTimer.user = user;
            mockTimer.restart();
        } else {
            if (Greetd.state !== GreetdState.Inactive)
                Greetd.cancelSession();
            Greetd.createSession(user);
        }
    }

    function cancel() {
        awaiting = false;
        busy = false;
        prompt = "";
        _hasSecret = false;
        if (!mock && Greetd.state !== GreetdState.Inactive)
            Greetd.cancelSession();
    }

    function _respond(text) {
        if (mock) {
            mockTimer.secret = text;
            mockTimer.restart();
        } else {
            Greetd.respond(text);
        }
    }

    function _onMessage(message, error, responseRequired, echoResponse) {
        if (!responseRequired) {
            info = message;
            return;
        }
        // The first password prompt is answered with what the user already
        // typed; any further prompt is handed to the UI.
        if (_hasSecret && !echoResponse) {
            _hasSecret = false;
            const s = _secret;
            _secret = "";
            _respond(s);
            return;
        }
        prompt = message.replace(/:\s*$/, "");
        echo = echoResponse;
        awaiting = true;
        busy = false;
    }

    function _onFailure(message) {
        awaiting = false;
        busy = false;
        prompt = "";
        _hasSecret = false;
        _secret = "";
        failed(message);
    }

    function _onReady() {
        busy = true;
        succeeded();
        launchDelay.restart();
    }

    // Lets the fade-out play before greetd replaces us with the session.
    Timer {
        id: launchDelay
        interval: Theme.animSlow
        onTriggered: {
            if (root.mock) {
                console.log("[mock] launch", JSON.stringify(root._command), JSON.stringify(root._env));
                Qt.quit();
            } else {
                Greetd.launch(root._command, root._env, true);
            }
        }
    }

    Connections {
        target: root.mock ? null : Greetd
        function onAuthMessage(message, error, responseRequired, echoResponse) {
            root._onMessage(message, error, responseRequired, echoResponse);
        }
        function onAuthFailure(message) { root._onFailure(message); }
        function onReadyToLaunch() { root._onReady(); }
        function onError(error) { root._onFailure(error); }
    }

    // -- mock backend -----------------------------------------------------
    Timer {
        id: mockTimer
        property string user: ""
        property string secret: ""
        interval: 450
        onTriggered: {
            if (root._hasSecret) {
                root._onMessage("Password:", false, true, false);
            } else if (secret === "test") {
                secret = "";
                root._onReady();
            } else {
                secret = "";
                root._onFailure("Authentication failed");
            }
        }
    }
}
