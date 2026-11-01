pragma Singleton

import QtQuick
import Quickshell

// Which popup is open, plus shell-wide toggles. Only one popup at a time.
Singleton {
    id: root

    property bool launcherOpen: false
    property bool controlCenterOpen: false
    property bool calendarOpen: false
    property bool powerOpen: false
    property string ccPage: "home"
    property bool dnd: false

    function closeAll() {
        launcherOpen = false;
        controlCenterOpen = false;
        calendarOpen = false;
        powerOpen = false;
    }
    function toggleLauncher() { const o = !launcherOpen; closeAll(); launcherOpen = o; }
    function toggleCalendar() { const o = !calendarOpen; closeAll(); calendarOpen = o; }
    function togglePower() { const o = !powerOpen; closeAll(); powerOpen = o; }
    function toggleControlCenter(page) {
        if (page && page !== "" && controlCenterOpen && ccPage !== page) {
            ccPage = page;
            return;
        }
        const o = !controlCenterOpen;
        closeAll();
        if (page && page !== "") ccPage = page;
        controlCenterOpen = o;
    }

    function terminal(args) {
        Quickshell.execDetached([Theme.terminal].concat(args || []));
    }
}
