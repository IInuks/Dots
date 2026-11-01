import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Io
import "../components"
import ".."

// A tty login on an old monitor: the window powers on like a CRT, the
// banner types itself out, text glows in the wallpaper's accent, scanlines
// roll over everything.
Item {
    id: root

    property var ctl: null
    property bool preview: false

    readonly property color ink: Qt.hsla(Theme.hue, 0.35, 0.84, 1)
    readonly property color inkDim: Qt.hsla(Theme.hue, 0.25, 0.56, 1)
    readonly property color inkFaint: Qt.hsla(Theme.hue, 0.2, 0.34, 1)
    readonly property int fontSize: 16

    property string host: "localhost"
    property string kernel: ""

    function focusField() { field.forceActiveFocus(); }

    Process {
        running: true
        command: ["uname", "-nrm"]
        stdout: StdioCollector {
            onStreamFinished: {
                const f = text.trim().split(/\s+/);
                if (f.length >= 3) {
                    root.host = f[0];
                    root.kernel = f[1] + " " + f[2];
                }
            }
        }
    }

    // -- background ---------------------------------------------------------
    Backdrop {
        anchors.fill: parent
        blur: 1.0
        brightness: -0.45
        saturation: 0.15
    }
    Rectangle {
        anchors.fill: parent
        color: Qt.hsla(Theme.hue, 0.3, 0.03, 0.55)
    }

    // -- the terminal window --------------------------------------------------
    Rectangle {
        id: term
        anchors.centerIn: parent
        width: Math.min(860, parent.width * 0.62)
        height: body.implicitHeight + titleBar.height + footer.height + 56
        radius: 10
        color: Qt.hsla(Theme.hue, 0.3, 0.045, 0.94)
        border.width: 1
        border.color: field.error !== "" ? Qt.alpha(Theme.danger, 0.8) : Qt.alpha(Theme.accent, 0.35)
        Behavior on border.color { ColorAnimation { duration: Theme.animMid } }

        transform: [
            Scale { id: crt; origin.x: term.width / 2; origin.y: term.height / 2; xScale: 0; yScale: 0.006 },
            Translate { id: shift }
        ]
        Shake { id: shake; shift: shift; amount: 8 }

        RectangularShadow {
            z: -1
            anchors.fill: parent
            radius: parent.radius
            blur: 60
            spread: 4
            color: Qt.alpha(Theme.accent, 0.16)
        }

        // -- title bar --------------------------------------------------------
        Item {
            id: titleBar
            width: parent.width
            height: 36
            Row {
                anchors.left: parent.left
                anchors.leftMargin: 14
                anchors.verticalCenter: parent.verticalCenter
                spacing: 8
                Repeater {
                    model: [Theme.danger, Qt.hsla((Theme.hue + 0.12) % 1, 0.6, 0.6, 1), Theme.accent]
                    Rectangle { required property color modelData; width: 12; height: 12; radius: 6; color: modelData; opacity: 0.85 }
                }
            }
            Text {
                anchors.centerIn: parent
                text: "greetd@" + root.host + ": /dev/tty7"
                color: root.inkFaint
                font.family: Theme.fontMono
                font.pixelSize: Theme.fontS
            }
            Rectangle { anchors.bottom: parent.bottom; width: parent.width; height: 1; color: Qt.alpha(Theme.accent, 0.15) }
        }

        // -- body: banner + login prompt --------------------------------------
        Column {
            id: body
            anchors.top: titleBar.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.margins: 28
            spacing: 6

            // phosphor glow
            layer.enabled: true
            layer.effect: MultiEffect {
                shadowEnabled: true
                shadowColor: Qt.alpha(Theme.accent, 0.7)
                shadowBlur: 0.5
                shadowHorizontalOffset: 0
                shadowVerticalOffset: 0
            }

            TypeLine { full: "Welcome to quickdots on " + root.host + " (tty7)"; delay: 700; color: Theme.accent }
            TypeLine { full: root.kernel !== "" ? "Linux " + root.kernel : "Linux"; delay: 1000; color: root.inkDim }
            TypeLine { full: Qt.locale().toString(clock.date, "ddd d MMM yyyy  HH:mm"); delay: 1250; color: root.inkDim }
            Item { width: 1; height: 10 }

            // login: <user>
            Row {
                id: loginRow
                spacing: 0
                opacity: 0
                Reveal on opacity { delay: 1500 }
                Text { text: root.host + " login: "; color: root.ink; font.family: Theme.fontMono; font.pixelSize: root.fontSize }
                Text {
                    text: root.ctl.user ? root.ctl.user.name : "?"
                    color: userMouse.containsMouse ? Theme.accent : root.ink
                    font.family: Theme.fontMono
                    font.pixelSize: root.fontSize
                    font.bold: true
                    MouseArea {
                        id: userMouse
                        anchors.fill: parent
                        enabled: root.ctl.multiUser
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.ctl.cycleUser(1)
                    }
                }
                Text {
                    visible: root.ctl.multiUser
                    text: "   [M-←/→ switch]"
                    color: root.inkFaint
                    font.family: Theme.fontMono
                    font.pixelSize: root.fontSize
                }
            }

            // Password: ****█
            Row {
                spacing: 0
                opacity: 0
                Reveal on opacity { delay: 1700 }
                Text {
                    text: (Auth.awaiting && Auth.prompt !== "" ? Auth.prompt : "Password") + ": "
                    color: root.ink
                    font.family: Theme.fontMono
                    font.pixelSize: root.fontSize
                }
                PasswordField {
                    id: field
                    width: Math.max(20, contentWidth + 12)
                    ctl: root.ctl
                    preview: root.preview
                    color: root.ink
                    font.family: Theme.fontMono
                    font.pixelSize: root.fontSize
                    font.letterSpacing: 0
                    passwordCharacter: "*"
                    cursorDelegate: Item {}
                    onRejected: shake.restart()

                    // block cursor, blinking
                    Rectangle {
                        x: field.contentWidth + 1
                        anchors.verticalCenter: parent.verticalCenter
                        width: root.fontSize * 0.6
                        height: root.fontSize * 1.15
                        color: Theme.accent
                        visible: !Auth.busy
                        SequentialAnimation on opacity {
                            loops: Animation.Infinite
                            NumberAnimation { to: 1; duration: 0 }
                            PauseAnimation { duration: 530 }
                            NumberAnimation { to: 0; duration: 0 }
                            PauseAnimation { duration: 530 }
                        }
                    }
                }
            }

            // status line
            Text {
                readonly property var spin: ["⠋", "⠙", "⠹", "⠸", "⠼", "⠴", "⠦", "⠧", "⠇", "⠏"]
                property int frame: 0
                height: root.fontSize * 1.5
                text: Auth.busy ? spin[frame] + " authenticating " + (root.ctl.user ? root.ctl.user.name : "") + "…"
                    : field.error !== "" ? "Login incorrect: " + field.error
                    : Auth.info
                color: field.error !== "" ? Theme.danger : root.inkDim
                font.family: Theme.fontMono
                font.pixelSize: root.fontSize
                Timer { running: Auth.busy; repeat: true; interval: 80; onTriggered: parent.frame = (parent.frame + 1) % 10 }
            }

            // session: mango [M-↑/↓]
            Row {
                opacity: 0
                Reveal on opacity { delay: 1900 }
                Text { text: "session: "; color: root.inkDim; font.family: Theme.fontMono; font.pixelSize: root.fontSize }
                Text {
                    text: "<" + (root.ctl.session ? root.ctl.session.name : "none") + ">"
                    color: sesMouse.containsMouse ? Theme.accent : root.ink
                    font.family: Theme.fontMono
                    font.pixelSize: root.fontSize
                    MouseArea {
                        id: sesMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: { root.ctl.cycleSession(1); field.forceActiveFocus(); }
                    }
                }
                Text { text: "   [M-↑/↓ cycle]"; color: root.inkFaint; font.family: Theme.fontMono; font.pixelSize: root.fontSize }
            }
        }

        // -- nano-style footer: keys + power commands ------------------------
        Rectangle {
            id: footer
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 1
            anchors.horizontalCenter: parent.horizontalCenter
            width: parent.width - 2
            height: 40
            radius: 9
            color: Qt.alpha(Theme.accent, 0.07)
            opacity: 0
            Reveal on opacity { delay: 2100 }

            Row {
                anchors.left: parent.left
                anchors.leftMargin: 14
                anchors.verticalCenter: parent.verticalCenter
                spacing: 18
                Key { cap: "M-S"; label: "Style"; onClicked: root.ctl.openStyles() }
                Key { cap: "⏎"; label: "Login"; onClicked: field.submit() }
                Key { cap: "Esc"; label: "Clear"; onClicked: { field.text = ""; field.error = ""; Auth.cancel(); } }
            }
            Row {
                anchors.right: parent.right
                anchors.rightMargin: 14
                anchors.verticalCenter: parent.verticalCenter
                spacing: 6
                Cmd { label: "suspend"; onClicked: root.ctl.power("suspend") }
                Cmd { label: "reboot"; onClicked: root.ctl.power("reboot") }
                Cmd { label: "poweroff"; danger: true; onClicked: root.ctl.power("poweroff") }
            }
        }
    }

    SystemClock { id: clock; precision: SystemClock.Minutes }

    // -- CRT overlay: scanlines + a slowly rolling bright band ---------------
    Canvas {
        anchors.fill: parent
        opacity: 0.5
        onWidthChanged: requestPaint()
        onHeightChanged: requestPaint()
        onPaint: {
            const ctx = getContext("2d");
            ctx.clearRect(0, 0, width, height);
            ctx.fillStyle = "rgba(0, 0, 0, 0.35)";
            for (let y = 0; y < height; y += 3)
                ctx.fillRect(0, y, width, 1);
        }
    }
    Rectangle {
        id: band
        width: parent.width
        height: 160
        gradient: Gradient {
            GradientStop { position: 0; color: "transparent" }
            GradientStop { position: 0.5; color: Qt.alpha(Theme.accent, 0.05) }
            GradientStop { position: 1; color: "transparent" }
        }
        NumberAnimation on y {
            from: -160
            to: root.height
            duration: 8000
            loops: Animation.Infinite
        }
    }

    // CRT power-on: a dot widens into a line, the line opens up, a flicker
    SequentialAnimation {
        running: true
        PauseAnimation { duration: 150 }
        NumberAnimation { target: crt; property: "xScale"; to: 1; duration: 220; easing.type: Easing.OutCubic }
        NumberAnimation { target: crt; property: "yScale"; to: 1; duration: 300; easing.type: Easing.OutBack }
        NumberAnimation { target: term; property: "opacity"; to: 0.55; duration: 50 }
        NumberAnimation { target: term; property: "opacity"; to: 1; duration: 70 }
        NumberAnimation { target: term; property: "opacity"; to: 0.8; duration: 40 }
        NumberAnimation { target: term; property: "opacity"; to: 1; duration: 60 }
    }

    // a line of text that types itself out after `delay` ms
    component TypeLine: Text {
        id: line
        property string full: ""
        property int delay: 0
        property real progress: 0
        text: full.substring(0, Math.ceil(full.length * progress))
        font.family: Theme.fontMono
        font.pixelSize: root.fontSize
        SequentialAnimation on progress {
            PauseAnimation { duration: line.delay }
            NumberAnimation { to: 1; duration: 520 }
        }
    }
    // pops a line in after `delay` ms (value source on opacity)
    component Reveal: SequentialAnimation {
        property int delay: 0
        running: true
        PauseAnimation { duration: delay }
        NumberAnimation { to: 1; duration: 1 }
    }
    component Key: Item {
        id: key
        property string cap
        property string label
        signal clicked()
        implicitWidth: keyRow.implicitWidth
        implicitHeight: keyRow.implicitHeight
        Row {
        id: keyRow
        spacing: 6
        Rectangle {
            anchors.verticalCenter: parent.verticalCenter
            width: capText.implicitWidth + 10
            height: 20
            radius: 4
            color: keyMouse.containsMouse ? Theme.accent : root.ink
            Behavior on color { ColorAnimation { duration: Theme.animFast } }
            Text { id: capText; anchors.centerIn: parent; text: key.cap; color: Theme.accentText; font.family: Theme.fontMono; font.pixelSize: Theme.fontS; font.bold: true }
        }
        Text { anchors.verticalCenter: parent.verticalCenter; text: key.label; color: root.inkDim; font.family: Theme.fontMono; font.pixelSize: Theme.fontS }
        }
        MouseArea { id: keyMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: key.clicked() }
    }
    component Cmd: Text {
        id: cmd
        property string label
        property bool danger: false
        signal clicked()
        text: "[" + label + "]"
        color: cmdMouse.containsMouse ? (danger ? Theme.danger : Theme.accent) : root.inkDim
        font.family: Theme.fontMono
        font.pixelSize: Theme.fontS
        Behavior on color { ColorAnimation { duration: Theme.animFast } }
        MouseArea { id: cmdMouse; anchors.fill: parent; anchors.margins: -4; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: cmd.clicked() }
    }
}
