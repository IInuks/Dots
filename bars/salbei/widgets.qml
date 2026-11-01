//@ pragma UseQApplication
import QtQuick
import Quickshell
import "."
import "modules/widgets"

// Widgets-only host: salbei's desktop layer (Desktop.qml) without the bar,
// for when another bar is active. Started/stopped by the quickdots menu
// (menu/scripts/widgets-host.sh) -- never together with salbei itself,
// which has its own Desktop. Lives here so it sees salbei's singletons and
// reads the same salbei-widgets.json.
ShellRoot {
    Variants {
        model: Quickshell.screens
        Desktop {}
    }
}
