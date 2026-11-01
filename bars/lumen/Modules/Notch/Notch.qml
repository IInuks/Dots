import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Services.Pipewire
import "../.."

// Die komplette Rice ist EIN schwebendes Fenster, das sich VERFORMT: Pille
// (nur Uhr) <-> Settings-Karte (Tags/Musik/Audio/System/Schnellzugriff/
// Energie) <-> Suche (Fuzzy-Launcher) <-> Wallpaper-Grid. Kein zweites
// Fenster, keine Luecke -- Suche/Wallpaper waren zunaechst eigene,
// top-verankerte Popup-Fenster direkt unter der Pille, das las sich aber
// immer noch als "eigenes Menue mit Gap" statt als dieselbe Bar. Jetzt
// animiert dieselbe Surface einfach zwischen vier Zielgroessen
// (Settings.notchExpandedWidth/searchWidth/wallpaperWidth x je eigener
// Hoehe), Inhalt wird per Sichtbarkeits-Umschaltung getauscht.
//
// Kein linkes/rechtes/unteres Anchor: bei wlr-layer-shell zentriert der
// Compositor eine nur-oben-verankerte Surface automatisch horizontal --
// bestaetigtes Muster aus bars/floating/IslandBase.qml.
PanelWindow {
    id: notch

    required property var modelData
    // Von shell.qml durchgereicht -- haelt den geteilten Zustand
    // (menuOpen/menuSubview), den auch der SUPER+Space-IPC-Handler
    // schreibt. NICHT "shellRoot" genannt: siehe
    // feedback_qml_child_property_shadows_outer_id -- ein Property mit
    // demselben Namen wie die aeussere id schattiert sich sonst lautlos
    // auf "undefined".
    required property var appRoot
    screen: modelData

    // Reiner Hover-Vorschau-Zustand (nicht "angepinnt"). "settings" zeigt
    // sich schon bei blossem Hover; "search"/"wallpaper" werden dagegen nur
    // durch einen Klick (Chip) oder IPC "angepinnt" (appRoot.menuOpen) und
    // schliessen NICHT durch Hover-Exit -- sonst wuerde Mausbewegung beim
    // Tippen versehentlich die Suche zuklappen.
    property bool hovering: false
    readonly property bool expanded: notch.appRoot.menuOpen || notch.hovering
    readonly property string subview: notch.appRoot.menuOpen ? notch.appRoot.menuSubview : "settings"

    function closeMenu() {
        notch.appRoot.menuOpen = false;
    }
    function collapseAll() {
        notch.appRoot.menuOpen = false;
        notch.hovering = false;
        closeTimer.stop();
    }

    anchors.top: true
    // TopGapReserve.qml reserviert Settings.notchTopReserveZone auf
    // demselben Bildschirmrand -- mango stapelt gleich-kantige
    // Layer-Shell-Surfaces, indem es jede um die exclusiveZone der jeweils
    // anderen nach unten schiebt (bestaetigt in bars/floating/IslandBase.qml).
    // Diese Verschiebung hier zurueckrechnen, sonst haengt der Notch
    // sichtbar tiefer als notchMarginTop.
    margins.top: Settings.notchMarginTop - Settings.notchTopReserveZone

    color: "transparent"
    implicitWidth: body.width
    implicitHeight: body.height
    exclusiveZone: 0

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "lumen-notch"
    // OnDemand von Anfang an (nie umgeschaltet): mango gewaehrt einer
    // Layer-Surface Keyboard-Fokus nur bei ihrem allerersten Commit ODER
    // bei einem Klick auf eine bereits-als-OnDemand-committete Surface --
    // NIE beim nachtraeglichen Umschalten einer bestehenden Surface von
    // None/Exclusive auf OnDemand (siehe
    // feedback_mango_ondemand_focus_requires_fresh_surface). Da diese
    // Surface fuer das Suchfeld dauerhaft existieren MUSS (kein zweites
    // Fenster mehr, das waere wieder die "Luecke"), bleibt OnDemand hier
    // fest stehen; ein Klick auf den Notch (z.B. der "Suchen"-Chip) zaehlt
    // als genau der "Klick auf bereits-OnDemand-Surface"-Fall und gewaehrt
    // Fokus zuverlaessig. Nebenwirkung: jeder Klick auf den Notch holt sich
    // kurz den Tastaturfokus, auch in der reinen Settings-Ansicht -- siehe
    // README "Bekannte Luecken".
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand

    // -- WLAN-Status (NetworkManager) --
    property bool wifiEnabled: true
    function _refreshWifi() {
        wifiStatusProc.running = false;
        wifiStatusProc.running = true;
    }
    Process {
        id: wifiStatusProc
        command: ["sh", "-c", Settings.wifiStatusCommand]
        stdout: StdioCollector {
            onStreamFinished: notch.wifiEnabled = text.trim() === "enabled"
        }
    }
    function toggleWifi() {
        Quickshell.execDetached(["sh", "-c", notch.wifiEnabled ? Settings.wifiToggleOffCommand : Settings.wifiToggleOnCommand]);
        wifiRefreshTimer.start();
    }
    Timer {
        id: wifiRefreshTimer
        interval: 600
        onTriggered: notch._refreshWifi()
    }
    Component.onCompleted: notch._refreshWifi()

    // Verzoegertes Schliessen der reinen Hover-Vorschau (nicht des
    // "angepinnten" search/wallpaper-Zustands, siehe expanded/subview oben).
    Timer {
        id: closeTimer
        interval: Settings.notchCloseDelayMs
        onTriggered: notch.hovering = false
    }

    Item {
        id: body

        width: {
            if (!notch.expanded)
                return collapsedClock.implicitWidth + Settings.notchPadding * 2;
            if (notch.subview === "search")
                return Settings.searchWidth;
            if (notch.subview === "wallpaper")
                return Settings.wallpaperWidth;
            return Settings.notchExpandedWidth;
        }
        height: {
            if (!notch.expanded)
                return Settings.notchCollapsedHeight;
            if (notch.subview === "search")
                return Settings.searchHeight;
            if (notch.subview === "wallpaper")
                return Settings.wallpaperHeight;
            return settingsColumn.implicitHeight + Settings.notchPadding * 2;
        }

        Behavior on width {
            NumberAnimation { duration: Settings.notchAnimationMs; easing.type: Easing.OutExpo }
        }
        Behavior on height {
            NumberAnimation { duration: Settings.notchAnimationMs; easing.type: Easing.OutExpo }
        }

        Rectangle {
            id: card
            anchors.fill: parent
            radius: Settings.notchRadius
            color: Qt.alpha(Colors.panel, 0.96)
            border.width: 1
            // Warmer Akzent-Rand statt neutralem Trenner -- eigene
            // Bildmarke statt generischem Panel-Look.
            border.color: Qt.alpha(Colors.accent, 0.35)
            // Wichtig fuer den Verform-Effekt: jede Subview-Spalte hat eine
            // FESTE Breite (siehe dort) und wird waehrend der
            // Groessen-Animation einfach zunehmend sichtbar, statt live
            // mitzuskalieren -- sonst wuerde jede Zeile waehrend der 260ms
            // Animation staendig neu umbrechen.
            clip: true

            // Globales Escape fuer ALLE Subviews (Settings/Suche/Wallpaper),
            // nicht nur fuer die Suche (die faengt Escape zusaetzlich schon
            // direkt im Suchfeld ab, siehe SearchField.qml -- dort
            // akzeptiert, bubbelt also gar nicht erst bis hierher hoch).
            // "focus: notch.expanded" fordert Tastaturfokus fuer die Karte
            // an, sobald sie sich oeffnet; Klicks auf Unterelemente (z.B.
            // das Suchfeld) uebernehmen den Fokus danach ganz normal per
            // forceActiveFocus(). Greift nur, wenn diese Surface ueberhaupt
            // echten Wayland-Tastaturfokus hat (siehe Kommentar bei
            // WlrLayershell.keyboardFocus oben) -- bei reinem Hover ohne
            // vorherigen Klick kommt die Taste evtl. gar nicht hier an,
            // dann schliesst stattdessen einfach die Maus-weg-Verzoegerung.
            focus: notch.expanded
            Keys.onEscapePressed: {
                if (notch.appRoot.menuOpen) {
                    notch.closeMenu();
                } else {
                    notch.hovering = false;
                    closeTimer.stop();
                }
            }

            MouseArea {
                id: hoverArea
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onEntered: {
                    closeTimer.stop();
                    notch.hovering = true;
                }
                onExited: closeTimer.start()
                onClicked: notch.hovering = true
            }

            Clock {
                id: collapsedClock
                anchors.centerIn: parent
                format: Settings.clockFormatCollapsed
                pointSize: Colors.fontSize + 1
                opacity: notch.expanded ? 0 : 1
                visible: opacity > 0.01
                Behavior on opacity {
                    NumberAnimation { duration: Settings.notchAnimationMs / 2 }
                }
            }

            // ================= Subview: Settings =================
            Column {
                id: settingsColumn
                width: Settings.notchExpandedWidth - Settings.notchPadding * 2
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.top: parent.top
                anchors.topMargin: Settings.notchPadding
                spacing: Settings.notchSectionSpacing
                opacity: (notch.expanded && notch.subview === "settings") ? 1 : 0
                visible: opacity > 0.01
                Behavior on opacity {
                    NumberAnimation { duration: Settings.notchAnimationMs / 2 }
                }

                // -- Kopfzeile: Tags + Uhr --
                RowLayout {
                    width: parent.width
                    Workspaces {
                        screen: notch.screen
                        Layout.alignment: Qt.AlignVCenter
                    }
                    Item { Layout.fillWidth: true }
                    Clock {
                        Layout.alignment: Qt.AlignVCenter
                    }
                }

                Media {
                    width: parent.width
                }

                // -- Sektion: Audio --
                Column {
                    width: parent.width
                    spacing: Settings.notchRowSpacing

                    Text {
                        text: "AUDIO"
                        font.family: Colors.fontFamily
                        font.pointSize: Colors.fontSize - 2
                        font.letterSpacing: 1.2
                        color: Colors.accentAlt
                    }

                    RowLayout {
                        id: volumeRow
                        width: parent.width
                        spacing: 10

                        readonly property var sink: Pipewire.defaultAudioSink
                        readonly property bool hasAudio: sink !== null && sink.audio !== null

                        PwObjectTracker {
                            objects: volumeRow.sink !== null ? [volumeRow.sink] : []
                        }

                        Text {
                            text: {
                                if (!volumeRow.hasAudio || volumeRow.sink.audio.muted)
                                    return ""; // nf-fa-volume_mute
                                return volumeRow.sink.audio.volume < 0.5 ? "" : "";
                            }
                            font.family: Colors.fontFamily
                            font.pointSize: Colors.fontSize
                            color: volumeRow.hasAudio && !volumeRow.sink.audio.muted ? Colors.text : Colors.textDim

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: if (volumeRow.hasAudio)
                                    volumeRow.sink.audio.muted = !volumeRow.sink.audio.muted
                            }
                        }

                        Item {
                            Layout.fillWidth: true
                            implicitHeight: 14

                            Rectangle {
                                id: volumeTrack
                                anchors.left: parent.left
                                anchors.right: parent.right
                                anchors.verticalCenter: parent.verticalCenter
                                height: Settings.sliderHeight
                                radius: height / 2
                                color: Colors.panelAlt
                            }
                            Rectangle {
                                anchors.left: parent.left
                                anchors.verticalCenter: parent.verticalCenter
                                width: volumeTrack.width * (volumeRow.hasAudio ? volumeRow.sink.audio.volume : 0)
                                height: Settings.sliderHeight
                                radius: height / 2
                                color: Colors.accent
                            }
                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onPressed: mouse => {
                                    if (volumeRow.hasAudio)
                                        volumeRow.sink.audio.volume = Math.max(0, Math.min(1, mouse.x / width));
                                }
                                onPositionChanged: mouse => {
                                    if (pressed && volumeRow.hasAudio)
                                        volumeRow.sink.audio.volume = Math.max(0, Math.min(1, mouse.x / width));
                                }
                            }
                        }
                    }

                    RowLayout {
                        id: micRow
                        width: parent.width

                        readonly property var source: Pipewire.defaultAudioSource
                        readonly property bool hasMic: source !== null && source.audio !== null
                        readonly property bool muted: !hasMic || source.audio.muted

                        PwObjectTracker {
                            objects: micRow.source !== null ? [micRow.source] : []
                        }

                        Text {
                            text: micRow.muted ? "" : "" // nf-fa-microphone_slash / nf-fa-microphone
                            font.family: Colors.fontFamily
                            font.pointSize: Colors.fontSize
                            color: micRow.muted ? Colors.textDim : Colors.text
                        }
                        Text {
                            text: "Mikrofon"
                            font.family: Colors.fontFamily
                            font.pointSize: Colors.fontSize
                            font.letterSpacing: Colors.letterSpacing
                            color: Colors.text
                            Layout.fillWidth: true
                        }
                        Rectangle {
                            width: Settings.toggleWidth
                            height: Settings.toggleHeight
                            radius: height / 2
                            color: !micRow.muted ? Colors.accent : Colors.panelAlt

                            Rectangle {
                                width: parent.height - 4
                                height: parent.height - 4
                                radius: width / 2
                                color: Colors.bg
                                y: 2
                                x: !micRow.muted ? parent.width - width - 2 : 2
                                Behavior on x {
                                    NumberAnimation { duration: 150; easing.type: Easing.OutCubic }
                                }
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: if (micRow.hasMic)
                                    micRow.source.audio.muted = !micRow.source.audio.muted
                            }
                        }
                    }
                }

                // -- Sektion: System --
                Column {
                    width: parent.width
                    spacing: Settings.notchRowSpacing

                    Text {
                        text: "SYSTEM"
                        font.family: Colors.fontFamily
                        font.pointSize: Colors.fontSize - 2
                        font.letterSpacing: 1.2
                        color: Colors.accentAlt
                    }

                    RowLayout {
                        width: parent.width

                        Text {
                            text: "Nicht stören"
                            font.family: Colors.fontFamily
                            font.pointSize: Colors.fontSize
                            font.letterSpacing: Colors.letterSpacing
                            color: Colors.text
                            Layout.fillWidth: true
                        }

                        Rectangle {
                            width: Settings.toggleWidth
                            height: Settings.toggleHeight
                            radius: height / 2
                            color: Settings.dndEnabled ? Colors.accent : Colors.panelAlt

                            Rectangle {
                                width: parent.height - 4
                                height: parent.height - 4
                                radius: width / 2
                                color: Colors.bg
                                y: 2
                                x: Settings.dndEnabled ? parent.width - width - 2 : 2
                                Behavior on x {
                                    NumberAnimation { duration: 150; easing.type: Easing.OutCubic }
                                }
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: Settings.dndEnabled = !Settings.dndEnabled
                            }
                        }
                    }

                    RowLayout {
                        width: parent.width

                        Text {
                            text: notch.wifiEnabled ? "" : "" // nf-fa-wifi / nf-fa-ban
                            font.family: Colors.fontFamily
                            font.pointSize: Colors.fontSize
                            color: notch.wifiEnabled ? Colors.text : Colors.textDim
                        }
                        Text {
                            text: "WLAN"
                            font.family: Colors.fontFamily
                            font.pointSize: Colors.fontSize
                            font.letterSpacing: Colors.letterSpacing
                            color: Colors.text
                            Layout.fillWidth: true
                        }
                        Rectangle {
                            width: Settings.toggleWidth
                            height: Settings.toggleHeight
                            radius: height / 2
                            color: notch.wifiEnabled ? Colors.accent : Colors.panelAlt

                            Rectangle {
                                width: parent.height - 4
                                height: parent.height - 4
                                radius: width / 2
                                color: Colors.bg
                                y: 2
                                x: notch.wifiEnabled ? parent.width - width - 2 : 2
                                Behavior on x {
                                    NumberAnimation { duration: 150; easing.type: Easing.OutCubic }
                                }
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: notch.toggleWifi()
                            }
                        }
                    }
                }

                // -- Sektion: Schnellzugriff --
                Column {
                    width: parent.width
                    spacing: Settings.notchRowSpacing

                    Text {
                        text: "SCHNELLZUGRIFF"
                        font.family: Colors.fontFamily
                        font.pointSize: Colors.fontSize - 2
                        font.letterSpacing: 1.2
                        color: Colors.accentAlt
                    }

                    RowLayout {
                        width: parent.width
                        spacing: 8

                        Rectangle {
                            Layout.fillWidth: true
                            implicitHeight: 32
                            radius: 8
                            color: launcherArea.containsMouse ? Colors.panelAlt : "transparent"
                            border.width: 1
                            border.color: Colors.divider

                            Text {
                                anchors.centerIn: parent
                                text: "  Suchen" // nf-fa-search
                                font.family: Colors.fontFamily
                                font.pointSize: Colors.fontSize
                                color: Colors.text
                            }

                            MouseArea {
                                id: launcherArea
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    notch.appRoot.menuOpen = true;
                                    notch.appRoot.menuSubview = "search";
                                    searchField.focusInput();
                                }
                            }
                        }

                        Rectangle {
                            Layout.fillWidth: true
                            implicitHeight: 32
                            radius: 8
                            color: wallpaperArea.containsMouse ? Colors.panelAlt : "transparent"
                            border.width: 1
                            border.color: Colors.divider

                            Text {
                                anchors.centerIn: parent
                                text: "  Wallpaper" // nf-fa-picture_o
                                font.family: Colors.fontFamily
                                font.pointSize: Colors.fontSize
                                color: Colors.text
                            }

                            MouseArea {
                                id: wallpaperArea
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    Wallpaper.rescan();
                                    notch.appRoot.menuOpen = true;
                                    notch.appRoot.menuSubview = "wallpaper";
                                }
                            }
                        }

                        Rectangle {
                            Layout.fillWidth: true
                            implicitHeight: 32
                            radius: 8
                            color: screenshotArea.containsMouse ? Colors.panelAlt : "transparent"
                            border.width: 1
                            border.color: Colors.divider

                            Text {
                                anchors.centerIn: parent
                                text: "  Screenshot" // nf-fa-camera
                                font.family: Colors.fontFamily
                                font.pointSize: Colors.fontSize
                                color: Colors.text
                            }

                            MouseArea {
                                id: screenshotArea
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    Quickshell.execDetached(["sh", "-c", Settings.screenshotCommand]);
                                    notch.collapseAll();
                                }
                            }
                        }
                    }
                }

                // -- Sektion: Energie --
                Column {
                    width: parent.width
                    spacing: Settings.notchRowSpacing

                    Text {
                        text: "ENERGIE"
                        font.family: Colors.fontFamily
                        font.pointSize: Colors.fontSize - 2
                        font.letterSpacing: 1.2
                        color: Colors.accentAlt
                    }

                    RowLayout {
                        width: parent.width

                        Repeater {
                            model: [
                                { icon: "", command: Settings.lockCommand },      // nf-fa-lock
                                { icon: "", command: Settings.logoutCommand },  // nf-fa-sign_out
                                { icon: "", command: Settings.rebootCommand },  // nf-fa-refresh
                                { icon: "", command: Settings.shutdownCommand } // nf-fa-power_off
                            ]

                            delegate: Rectangle {
                                required property var modelData

                                Layout.fillWidth: true
                                implicitHeight: 32
                                radius: 8
                                color: powerArea.containsMouse ? Colors.panelAlt : "transparent"

                                Text {
                                    anchors.centerIn: parent
                                    text: parent.modelData.icon
                                    font.family: Colors.fontFamily
                                    font.pointSize: Colors.fontSize + 1
                                    color: Colors.text
                                }

                                MouseArea {
                                    id: powerArea
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: Quickshell.execDetached(["sh", "-c", parent.modelData.command])
                                }
                            }
                        }
                    }
                }
            }

            // ================= Subview: Suche =================
            Item {
                id: searchView
                width: Settings.searchWidth - Settings.notchPadding * 2
                height: Settings.searchHeight - Settings.notchPadding * 2
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.top: parent.top
                anchors.topMargin: Settings.notchPadding
                opacity: (notch.expanded && notch.subview === "search") ? 1 : 0
                visible: opacity > 0.01
                Behavior on opacity {
                    NumberAnimation { duration: Settings.notchAnimationMs / 2 }
                }

                readonly property var results: Apps.list(searchField.text)
                property int selectedIndex: 0

                function launch(entry) {
                    if (!entry)
                        return;
                    Apps.recordUsage(entry.id);
                    entry.execute();
                    notch.closeMenu();
                }

                onVisibleChanged: if (visible)
                    searchField.focusInput()

                Item {
                    id: searchHeader
                    anchors.top: parent.top
                    anchors.left: parent.left
                    anchors.right: parent.right
                    height: 22

                    Text {
                        text: "SUCHEN"
                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter
                        font.family: Colors.fontFamily
                        font.pointSize: Colors.fontSize - 2
                        font.letterSpacing: 1.2
                        color: Colors.accentAlt
                    }
                    Text {
                        text: "" // nf-fa-close
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        font.family: Colors.fontFamily
                        font.pointSize: Colors.fontSize
                        color: searchCloseArea.containsMouse ? Colors.accent : Colors.textDim

                        MouseArea {
                            id: searchCloseArea
                            anchors.fill: parent
                            anchors.margins: -6
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: notch.closeMenu()
                        }
                    }
                }

                SearchField {
                    id: searchField
                    anchors.top: searchHeader.bottom
                    anchors.topMargin: 8
                    anchors.left: parent.left
                    anchors.right: parent.right
                    onTextChanged: searchView.selectedIndex = 0
                    onNavigateUp: searchView.selectedIndex = Math.max(0, searchView.selectedIndex - 1)
                    onNavigateDown: searchView.selectedIndex = Math.min(searchView.results.length - 1, searchView.selectedIndex + 1)
                    onActivateSelected: searchView.launch(searchView.results[searchView.selectedIndex])
                    onCancelled: notch.closeMenu()
                }

                Rectangle {
                    id: searchDivider
                    anchors.top: searchField.bottom
                    anchors.left: parent.left
                    anchors.right: parent.right
                    height: 1
                    color: Colors.divider
                }

                AppList {
                    anchors.top: searchDivider.bottom
                    anchors.topMargin: 6
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom
                    results: searchView.results
                    selectedIndex: searchView.selectedIndex
                    onActivated: index => searchView.launch(searchView.results[index])
                }
            }

            // ================= Subview: Wallpaper =================
            Item {
                id: wallpaperView
                width: Settings.wallpaperWidth - Settings.notchPadding * 2
                height: Settings.wallpaperHeight - Settings.notchPadding * 2
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.top: parent.top
                anchors.topMargin: Settings.notchPadding
                opacity: (notch.expanded && notch.subview === "wallpaper") ? 1 : 0
                visible: opacity > 0.01
                Behavior on opacity {
                    NumberAnimation { duration: Settings.notchAnimationMs / 2 }
                }

                Item {
                    id: wallpaperHeader
                    anchors.top: parent.top
                    anchors.left: parent.left
                    anchors.right: parent.right
                    height: 22

                    Text {
                        text: "WALLPAPER"
                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter
                        font.family: Colors.fontFamily
                        font.pointSize: Colors.fontSize - 2
                        font.letterSpacing: 1.2
                        color: Colors.accentAlt
                    }
                    Text {
                        text: "" // nf-fa-close
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        font.family: Colors.fontFamily
                        font.pointSize: Colors.fontSize
                        color: wallpaperCloseArea.containsMouse ? Colors.accent : Colors.textDim

                        MouseArea {
                            id: wallpaperCloseArea
                            anchors.fill: parent
                            anchors.margins: -6
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: notch.closeMenu()
                        }
                    }
                }

                GridView {
                    anchors.top: wallpaperHeader.bottom
                    anchors.topMargin: 8
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom
                    clip: true
                    cellWidth: Settings.wallpaperTileWidth + Settings.wallpaperTileSpacing
                    cellHeight: Settings.wallpaperTileHeight + Settings.wallpaperTileSpacing
                    model: Wallpaper.files

                    delegate: Item {
                        required property string modelData
                        width: Settings.wallpaperTileWidth
                        height: Settings.wallpaperTileHeight

                        WallpaperTile {
                            anchors.fill: parent
                            path: modelData
                            current: modelData === Wallpaper.current
                            onChosen: {
                                Wallpaper.apply(modelData);
                                notch.closeMenu();
                            }
                        }
                    }
                }
            }
        }
    }
}
