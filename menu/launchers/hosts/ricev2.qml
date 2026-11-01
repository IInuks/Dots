import Quickshell
import "Bar/launcher"

// Launcher-only host for bars/ricev2 (see the menu README, "Launcher
// mischen"). ricev2's Launcher brings its own `launcher` IpcHandler
// (toggle) and overlay window, so it only needs instantiating.
ShellRoot {
    Launcher {}
}
