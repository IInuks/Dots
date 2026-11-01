pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Desktop widget settings, edited live from the quickdots menu ("Widgets" tab).
// The menu is the only writer; this side only reads and reloads on change.
// Missing file / missing keys = the defaults below (same as the menu's
// WidgetsStore._defaults).
//
// Every widget <w> has <w>Visible, <w>X / <w>Y (top-left in % of the screen,
// clamped so the widget stays on screen; Y 100 = sits on the bottom edge),
// <w>Adapt (ink follows the wallpaper brightness under it) and, except the
// visualizer, <w>Backdrop (glass card behind it). Read them with v(key).
Singleton {
    id: root

    function v(key) { return file.adapter[key]; }

    // used outside the desktop layer (bar clock, control center)
    readonly property bool clock24h: file.adapter.clock24h

    FileView {
        id: file
        path: Quickshell.env("HOME") + "/.local/state/quickshell/salbei-widgets.json"
        watchChanges: true
        printErrors: false
        onFileChanged: reload()

        adapter: JsonAdapter {
            property bool clockVisible: true
            property real clockX: 2.5
            property real clockY: 13
            property bool clockAdapt: true
            property bool clockBackdrop: false
            property real clockSize: 112
            property bool clock24h: true
            property bool clockSeconds: false

            property bool analogVisible: false
            property real analogX: 2.5
            property real analogY: 45
            property bool analogAdapt: true
            property bool analogBackdrop: false
            property real analogSize: 180
            property bool analogSeconds: true
            property bool analogNumbers: false
            property bool analogTicks: true

            property bool calendarVisible: true
            property real calendarX: 79.2
            property real calendarY: 5.4
            property bool calendarAdapt: true
            property bool calendarBackdrop: false
            property bool calendarWeekNumbers: true
            property bool calendarEvents: true
            property real calendarWidth: 330

            property bool visualizerVisible: true
            property real visualizerX: 17.5
            property real visualizerY: 100
            property bool visualizerAdapt: true
            property real visualizerWidth: 65
            property real visualizerHeight: 64

            property bool greetingVisible: false
            property real greetingX: 2.5
            property real greetingY: 24
            property bool greetingAdapt: true
            property bool greetingBackdrop: false
            property real greetingScale: 1
            property string greetingName: ""
            property bool greetingDate: true

            property bool mediaVisible: false
            property real mediaX: 2.5
            property real mediaY: 80
            property bool mediaAdapt: true
            property bool mediaBackdrop: true
            property real mediaScale: 1
            property bool mediaArt: true
            property bool mediaControls: true
            property bool mediaAutoHide: true

            property bool systemVisible: false
            property real systemX: 86
            property real systemY: 80
            property bool systemAdapt: true
            property bool systemBackdrop: false
            property real systemScale: 1
            property bool systemCpu: true
            property bool systemRam: true
            property bool systemTemp: true

            property bool weatherVisible: false
            property real weatherX: 2.5
            property real weatherY: 33
            property bool weatherAdapt: true
            property bool weatherBackdrop: false
            property real weatherScale: 1
            property string weatherCity: ""
            property bool weatherFahrenheit: false
            property bool weatherDetails: true
        }
    }
}
