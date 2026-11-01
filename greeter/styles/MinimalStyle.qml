import QtQuick
import Quickshell
import "../components"
import ".."

// The wallpaper in full color and a huge thin clock whose digits roll over.
// Everything else sleeps and fades in on mouse movement or typing.
Item {
    id: root

    property var ctl: null
    property bool preview: false

    // controls visible -- after any activity, for a few seconds
    property bool active: true
    readonly property bool awake: preview || active || field.engaged

    function focusField() { field.forceActiveFocus(); }
    function wake() {
        active = true;
        sleepTimer.restart();
    }

    Timer {
        id: sleepTimer
        interval: 6000
        running: true
        onTriggered: root.active = false
    }
    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.NoButton
        onPositionChanged: root.wake()
    }

    Backdrop {
        anchors.fill: parent
        blur: field.engaged ? 0.55 : 0
        brightness: root.awake ? -0.1 : 0
        saturation: 1.0
        zoom: root.awake ? 1.0 : 1.035
        duration: 900
    }
    Rectangle {
        anchors.fill: parent
        gradient: Gradient {
            GradientStop { position: 0.35; color: "transparent" }
            GradientStop { position: 1.0; color: Qt.alpha(Theme.shade, Math.min(0.85, Theme.shade.a + 0.25)) }
        }
    }

    SystemClock { id: clock; precision: SystemClock.Minutes }

    // -- clock + login, bottom left ----------------------------------------
    Column {
        id: block
        anchors.left: parent.left
        anchors.bottom: parent.bottom
        anchors.leftMargin: Theme.edge * 2.2
        anchors.bottomMargin: Theme.edge * 2.2
        spacing: Theme.spacingS

        Row {
            id: digits
            readonly property string time: Qt.formatTime(clock.date, "HH:mm")
            readonly property int size: Math.max(96, Math.min(230, root.height * 0.24))
            Repeater {
                model: 5
                Digit {
                    required property int index
                    ch: digits.time.charAt(index)
                    size: digits.size
                    delay: index * 90
                }
            }
        }

        Text {
            text: Qt.locale().toString(clock.date, "dddd · d MMMM").toUpperCase()
            color: Theme.textDim
            font.family: Theme.fontSans
            font.pixelSize: Theme.fontM + 1
            font.letterSpacing: 6
            opacity: intro.dateFade
            leftPadding: 6
        }

        Item { width: 1; height: Theme.spacingXl }

        // user › password, with an underline that grows while awake
        Item {
            id: login
            width: 420
            height: 44
            opacity: root.awake ? 1 : 0
            transform: [Translate { y: root.awake ? 0 : 14; Behavior on y { NumberAnimation { duration: Theme.animSlow; easing.type: Easing.OutCubic } } }, Translate { id: shift }]
            Behavior on opacity { NumberAnimation { duration: Theme.animSlow } }
            Shake { id: shake; shift: shift }

            Text {
                id: who
                anchors.left: parent.left
                anchors.leftMargin: 6
                anchors.verticalCenter: parent.verticalCenter
                text: (root.ctl.user ? root.ctl.user.name : "?") + "  ›"
                color: Theme.accent
                font.family: Theme.fontSans
                font.pixelSize: Theme.fontL
                font.weight: Font.Medium
                MouseArea {
                    anchors.fill: parent
                    enabled: root.ctl.multiUser
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.ctl.cycleUser(1)
                }
            }
            PasswordField {
                id: field
                anchors.left: who.right
                anchors.leftMargin: Theme.spacingM
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                ctl: root.ctl
                preview: root.preview
                font.family: Theme.fontSans
                onTextChanged: root.wake()
                onRejected: shake.restart()
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    visible: field.text.length === 0
                    text: field.hint.toLowerCase()
                    color: Theme.textFaint
                    font.family: Theme.fontSans
                    font.pixelSize: Theme.fontM
                    font.italic: true
                }
            }
            Rectangle {
                anchors.bottom: parent.bottom
                anchors.left: parent.left
                height: Auth.busy ? 3 : 1.5
                width: root.awake ? parent.width : 0
                color: field.error !== "" ? Theme.danger : field.text.length > 0 ? Theme.accent : Qt.alpha(Theme.text, 0.4)
                Behavior on width { NumberAnimation { duration: 700; easing.type: Easing.OutQuart } }
                Behavior on color { ColorAnimation { duration: Theme.animMid } }
                // busy: a light runs along the line
                Rectangle {
                    visible: Auth.busy
                    width: 80
                    height: parent.height
                    gradient: Gradient {
                        orientation: Gradient.Horizontal
                        GradientStop { position: 0; color: "transparent" }
                        GradientStop { position: 0.5; color: Theme.text }
                        GradientStop { position: 1; color: "transparent" }
                    }
                    NumberAnimation on x { running: Auth.busy; from: -80; to: login.width; duration: 900; loops: Animation.Infinite }
                }
            }
        }
        Text {
            leftPadding: 6
            text: field.error !== "" ? field.error : Auth.info
            color: field.error !== "" ? Theme.danger : Theme.textDim
            font.family: Theme.fontSans
            font.pixelSize: Theme.fontS + 1
            opacity: text !== "" && root.awake ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: Theme.animFast } }
        }
    }

    // -- top right: plain glyph controls -----------------------------------
    Row {
        anchors.top: parent.top
        anchors.right: parent.right
        anchors.margins: Theme.edge
        spacing: Theme.spacingL
        opacity: root.awake ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: Theme.animSlow } }

        Glyph { glyph: "󰏘"; label: "style"; onClicked: root.ctl.openStyles() }
        Glyph {
            glyph: "󰍹"
            label: root.ctl.session ? root.ctl.session.name.toLowerCase() : "no session"
            showLabel: true
            onClicked: { root.ctl.cycleSession(1); field.forceActiveFocus(); }
        }
        Glyph { glyph: "󰤄"; label: "suspend"; onClicked: root.ctl.power("suspend") }
        Glyph { glyph: "󰜉"; label: "reboot"; onClicked: root.ctl.power("reboot") }
        Glyph { glyph: "󰐥"; label: "power off"; danger: true; onClicked: root.ctl.power("poweroff") }
    }

    QtObject {
        id: intro
        property real dateFade: 0
    }
    NumberAnimation { running: true; target: intro; property: "dateFade"; to: 1; duration: 900; easing.type: Easing.InQuad }

    // one clock digit: rises into place at start, rolls up on change
    component Digit: Item {
        id: digit
        property string ch: ""
        property int size: 160
        property int delay: 0
        property string shown: ""
        width: Math.max(cur.implicitWidth, ch === ":" ? size * 0.28 : size * 0.56)
        height: size * 1.12
        clip: true

        Text { id: old; y: -digit.height; text: ""; font: cur.font; color: cur.color }
        Text {
            id: cur
            anchors.horizontalCenter: parent.horizontalCenter
            y: digit.height
            text: digit.shown
            color: Theme.text
            font.family: Theme.fontSans
            font.pixelSize: digit.size
            font.weight: Font.Thin
        }

        onChChanged: {
            if (shown === "") { shown = ch; return; }
            if (ch === shown) return;
            old.text = shown;
            old.x = cur.x;
            shown = ch;
            roll.restart();
        }
        Component.onCompleted: { shown = ch; rise.start(); }

        SequentialAnimation {
            id: rise
            PauseAnimation { duration: 200 + digit.delay }
            NumberAnimation { target: cur; property: "y"; from: digit.height; to: 0; duration: 900; easing.type: Easing.OutQuart }
        }
        ParallelAnimation {
            id: roll
            NumberAnimation { target: old; property: "y"; from: 0; to: -digit.height; duration: 600; easing.type: Easing.InOutCubic }
            NumberAnimation { target: cur; property: "y"; from: digit.height; to: 0; duration: 600; easing.type: Easing.InOutCubic }
        }
    }

    component Glyph: Item {
        id: g
        property string glyph
        property string label
        property bool showLabel: false
        property bool danger: false
        signal clicked()
        implicitWidth: gRow.implicitWidth
        implicitHeight: gRow.implicitHeight
        Row {
        id: gRow
        spacing: Theme.spacingS
        Text {
            text: g.glyph
            color: gm.containsMouse ? (g.danger ? Theme.danger : Theme.accent) : Theme.text
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontL
            Behavior on color { ColorAnimation { duration: Theme.animFast } }
        }
        Text {
            anchors.verticalCenter: parent.verticalCenter
            visible: g.showLabel || gm.containsMouse
            text: g.label
            color: Theme.textDim
            font.family: Theme.fontSans
            font.pixelSize: Theme.fontM
        }
        }
        MouseArea { id: gm; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: g.clicked() }
    }
}
