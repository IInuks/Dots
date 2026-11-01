import Quickshell
import "Bar"
import "Bar/notifications"
import "Bar/power"
import "Bar/launcher"
import "Bar/switcher"

// Root: quickdots convention is `qs -p ~/quickdots/bars/ricev2`
// straight from this folder, NOT the original prompt's
// `~/.config/quickshell/skewbar/` + `qs -c skewbar` -- every other bar
// under quickdots/bars lives and launches this way, switched via
// quickdots/menu's adapters/*.json (see README "Installationsort").
ShellRoot {
    BarShell {}
    PopupHost {}
    PowerMenu {}
    Launcher {}
    Switcher {}
}
