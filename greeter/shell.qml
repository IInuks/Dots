import QtQuick
import Quickshell
import "components"
import "styles"

// quickdots greeter -- a greetd login screen.
//
// Runs as the only client of cage (see greetd/config.toml), which shows the
// FloatingWindow fullscreen. Inside a normal session it opens as a plain
// window with a mock backend (see Auth.qml / test.sh). The layouts live in
// styles/ (loaded by URL, so that directory is imported here too).
ShellRoot {
    FloatingWindow {
        id: win
        title: "quickdots greeter"
        color: Theme.bg
        implicitWidth: 1280
        implicitHeight: 800

        Greeter {
            anchors.fill: parent
        }
    }
}
