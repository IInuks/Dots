import QtQuick
import Quickshell

// Vollflaechiges Overlay mit dem Slice-basierten Wallpaper-Switcher. Wird
// per IPC (siehe shell.qml -> IpcHandler "coverflow" toggle) ein-/
// ausgeblendet. Layout/Interaktion 1:1 an quickdots/bars/ricev2s
// App-Launcher (Menues-Prompt Abschnitt 2, Bar/launcher/Launcher.qml)
// angelehnt: gedimmter Hintergrund, zentrierte Karte aus Such-Pill oben +
// horizontaler Slice-Reihe darunter, Keyboard-Handling in einem separaten
// fokussierbaren Item statt auf der ListView selbst.
FloatingWindow {
    id: overlayWindow

    required property var config
    required property var appState

    title: "shellwall-coverflow"
    visible: false
    color: "#00000000"
    fullscreen: true

    property string searchText: ""

    readonly property var filtered: {
        const needle = overlayWindow.searchText.trim().toLowerCase();
        if (needle.length === 0)
            return appState.wallpapers;
        return appState.wallpapers.filter(p => appState.basename(p).toLowerCase().includes(needle));
    }
    onFilteredChanged: {
        if (listView.currentIndex >= overlayWindow.filtered.length)
            listView.currentIndex = Math.max(0, overlayWindow.filtered.length - 1);
    }

    // Oeffnet/schliesst das Overlay ohne eine Auswahl zu uebernehmen.
    function toggle() {
        if (!overlayWindow.visible) {
            appState.refreshWallpapers();
        }
        overlayWindow.visible = !overlayWindow.visible;
        if (overlayWindow.visible) {
            overlayWindow.searchText = "";
            const idx = appState.wallpapers.indexOf(appState.current);
            listView.currentIndex = idx >= 0 ? idx : 0;
            keyHandler.forceActiveFocus();
            appState.requestResolution(listView.currentIndex);
        }
    }

    // apply=true -> aktuell fokussiertes Wallpaper setzen (Enter),
    // apply=false -> nur schliessen (Escape).
    function close(apply) {
        if (apply) {
            const path = overlayWindow.filtered[listView.currentIndex];
            if (path) appState.setWallpaper(path);
        }
        overlayWindow.visible = false;
    }

    function _next() {
        if (listView.currentIndex < overlayWindow.filtered.length - 1)
            listView.currentIndex++;
    }
    function _prev() {
        if (listView.currentIndex > 0)
            listView.currentIndex--;
    }
    function _activate() { overlayWindow.close(true); }

    Rectangle {
        id: dim
        anchors.fill: parent
        color: config.overlayBackgroundColor
        opacity: overlayWindow.visible ? 1 : 0

        Behavior on opacity {
            NumberAnimation { duration: config.anim300 }
        }

        MouseArea {
            anchors.fill: parent
            onClicked: overlayWindow.close(false)
        }

        Item {
            id: card
            anchors.centerIn: parent
            width: listView.width
            height: 65 + config.sliceHeight + 20
            opacity: 0

            states: State {
                name: "shown"
                when: overlayWindow.visible
                PropertyChanges { card.opacity: 1 }
            }
            transitions: [
                Transition {
                    from: ""; to: "shown"
                    NumberAnimation { target: card; property: "opacity"; duration: config.anim400; easing.type: Easing.OutCubic }
                },
                Transition {
                    from: "shown"; to: ""
                    NumberAnimation { target: card; property: "opacity"; duration: config.animFast }
                }
            ]

            // Schluckt Klicks, damit sie nicht durch die
            // Schliessen-bei-Klick-MouseArea des Dimmers durchfallen.
            MouseArea {
                anchors.fill: parent
            }

            SearchBar {
                id: searchBar
                config: overlayWindow.config
                searchText: overlayWindow.searchText
                y: 10
                anchors.horizontalCenter: parent.horizontalCenter
            }

            ListView {
                id: listView
                y: 65
                height: config.sliceHeight
                width: config.sliceExpandedWidth + (config.sliceVisibleCount - 1) * (config.sliceWidth + config.sliceSpacing)
                anchors.horizontalCenter: parent.horizontalCenter

                orientation: ListView.Horizontal
                interactive: false
                spacing: config.sliceSpacing
                model: overlayWindow.filtered

                readonly property int _spacerWidth: Math.max(0, (listView.width - config.sliceExpandedWidth) / 2)
                header: Item { width: listView._spacerWidth; height: 1 }
                footer: Item { width: listView._spacerWidth; height: 1 }

                add: Transition {
                    ParallelAnimation {
                        NumberAnimation { property: "opacity"; from: 0; to: 1; duration: config.animEnter }
                        NumberAnimation { property: "scale"; from: 0.85; to: 1; duration: config.animEnter }
                    }
                }
                remove: Transition {
                    NumberAnimation { property: "opacity"; to: 0; duration: config.animNormal; easing.type: Easing.InCubic }
                }
                move: Transition {
                    NumberAnimation { properties: "x,y"; duration: config.animMedium }
                }
                displaced: Transition {
                    NumberAnimation { properties: "x,y"; duration: config.animMedium }
                }

                // `index`/`modelData` werden hier NICHT redeklariert --
                // WallpaperSlice.qml deklariert sie schon als required
                // properties, Quickshell injiziert die ListView-Kontextwerte
                // automatisch in gleichnamige required properties des
                // Delegates (memory: feedback_qml_child_property_shadows_outer_id).
                delegate: WallpaperSlice {
                    config: overlayWindow.config
                    appState: overlayWindow.appState
                    selectedIndex: listView.currentIndex
                    onSelectRequested: listView.currentIndex = index
                    onActivated: overlayWindow._activate()
                }

                Timer {
                    id: resolveDebounce
                    interval: 90
                    onTriggered: appState.requestResolution(listView.currentIndex)
                }
                onCurrentIndexChanged: {
                    resolveDebounce.restart();
                    listView.positionViewAtIndex(listView.currentIndex, ListView.Center);
                }

                Text {
                    anchors.centerIn: parent
                    visible: listView.count === 0
                    text: "KEINE WALLPAPER"
                    font.pixelSize: 18
                    font.bold: true
                    font.letterSpacing: 2
                    color: config.tertiary
                }
            }
        }

        Item {
            id: keyHandler
            anchors.fill: parent
            focus: overlayWindow.visible
            Keys.onLeftPressed: overlayWindow._prev()
            Keys.onRightPressed: overlayWindow._next()
            Keys.onReturnPressed: overlayWindow._activate()
            Keys.onEnterPressed: overlayWindow._activate()
            Keys.onEscapePressed: overlayWindow.close(false)
            Keys.onPressed: event => {
                if (event.key === Qt.Key_Backspace) {
                    overlayWindow.searchText = overlayWindow.searchText.slice(0, -1);
                    listView.currentIndex = 0;
                    event.accepted = true;
                } else if (event.text.length > 0 && event.text >= " ") {
                    overlayWindow.searchText += event.text;
                    listView.currentIndex = 0;
                    event.accepted = true;
                }
            }
        }
    }
}
