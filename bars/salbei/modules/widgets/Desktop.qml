import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets
import "../../"
import "../../components"
import "../../services"

// Desktop layer: clock, analog clock, calendar, audio visualizer, greeting, media, system
// and weather straight on the wallpaper. Uses the Bottom layer (above the
// wallpaper tool's Background surface, below windows), so a restarted
// wallpaper daemon can never cover it. Only the calendar and the media
// controls take input. Every widget is a DeskWidget: visibility, position,
// size and "follow the wallpaper" come from WidgetSettings (quickdots menu,
// "Widgets" tab).
PanelWindow {
    id: desk

    required property var modelData
    screen: modelData

    anchors { top: true; bottom: true; left: true; right: true }
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"
    WlrLayershell.namespace: "qs-desktop"
    WlrLayershell.layer: WlrLayer.Bottom
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
    mask: Region {
        Region { item: calendarW.shown ? calendarW : null }
        Region { item: mediaW.shown && WidgetSettings.v("mediaControls") ? mediaW : null }
    }

    SystemClock { id: clock; precision: WidgetSettings.v("clockSeconds") ? SystemClock.Seconds : SystemClock.Minutes }
    SystemClock {
        id: analogClock
        enabled: analogW.shown
        precision: WidgetSettings.v("analogSeconds") ? SystemClock.Seconds : SystemClock.Minutes
    }

    Binding { target: Weather; property: "wanted"; value: weatherW.shown }
    Binding { target: Weather; property: "city"; value: WidgetSettings.v("weatherCity") ?? "" }

    // small round icon button for the media card
    component CardButton: Rectangle {
        id: cb
        property string icon
        property real size: 30
        property DeskWidget host
        property bool primary: false
        signal clicked()
        width: size
        height: size
        radius: size / 2
        color: primary ? host.accent : (cbMouse.containsMouse ? host.hoverTint : "transparent")
        Behavior on color { ColorAnimation { duration: Theme.animFast } }
        scale: cbMouse.pressed ? Theme.pressScale : 1
        Behavior on scale { NumberAnimation { duration: Theme.animNormal; easing.type: Theme.easingSpring } }
        Icon {
            anchors.centerIn: parent
            name: cb.icon
            size: cb.size * 0.6
            color: cb.primary ? cb.host.accentInk : cb.host.ink
        }
        MouseArea {
            id: cbMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: cb.clicked()
        }
    }

    // usage ring for the system widget
    component Ring: Column {
        id: ring
        property real value: 0               // 0..1
        property string label
        property string valueText
        property real size: 64
        property DeskWidget host
        spacing: 6
        Item {
            width: ring.size
            height: ring.size
            Canvas {
                id: arc
                anchors.fill: parent
                property real shown: ring.value
                Behavior on shown { NumberAnimation { duration: 700; easing.type: Theme.easing } }
                onShownChanged: requestPaint()
                property color trackColor: ring.host.track
                property color fill: ring.host.accent
                onTrackColorChanged: requestPaint()
                onFillChanged: requestPaint()
                renderStrategy: Canvas.Cooperative
                onPaint: {
                    const ctx = getContext("2d");
                    ctx.reset();
                    const lw = Math.max(3, ring.size * 0.09);
                    const r = width / 2 - lw / 2;
                    ctx.lineWidth = lw;
                    ctx.lineCap = "round";
                    ctx.strokeStyle = trackColor;
                    ctx.beginPath();
                    ctx.arc(width / 2, height / 2, r, 0, 2 * Math.PI);
                    ctx.stroke();
                    const v = Math.max(0, Math.min(1, shown));
                    if (v <= 0.005) return;
                    ctx.strokeStyle = fill;
                    ctx.beginPath();
                    ctx.arc(width / 2, height / 2, r, -Math.PI / 2, -Math.PI / 2 + v * 2 * Math.PI);
                    ctx.stroke();
                }
            }
            Txt {
                anchors.centerIn: parent
                text: ring.valueText
                color: ring.host.ink
                font.pixelSize: Math.round(ring.size * 0.22)
                font.weight: Font.DemiBold
            }
        }
        Txt {
            anchors.horizontalCenter: parent.horizontalCenter
            text: ring.label
            color: ring.host.inkDim
            font.pixelSize: Math.round(ring.size * 0.17)
            font.letterSpacing: 1
        }
    }

    Item {
        id: stage
        anchors.fill: parent

        // startup: widgets rise in one after another
        property real intro: 0
        property real introCal: 0
        SequentialAnimation {
            running: true
            PauseAnimation { duration: 300 }
            NumberAnimation { target: stage; property: "intro"; to: 1; duration: 1100; easing.type: Theme.easingEmph }
        }
        SequentialAnimation {
            running: true
            PauseAnimation { duration: 550 }
            NumberAnimation { target: stage; property: "introCal"; to: 1; duration: 900; easing.type: Theme.easingEmph }
        }

        // ── clock ────────────────────────────────────────────
        DeskWidget {
            id: clockW
            key: "clock"
            intro: stage.intro
            introDy: 40
            RollingText {
                text: Qt.formatTime(clock.date, (WidgetSettings.v("clock24h") ? "hh:mm" : "h:mm")
                                                + (WidgetSettings.v("clockSeconds") ? ":ss" : ""))
                color: clockW.accent
                pixelSize: WidgetSettings.v("clockSize")
                weight: Font.DemiBold
                letterSpacing: -4
                duration: 600
            }
        }

        // ── analog clock ─────────────────────────────────────
        DeskWidget {
            id: analogW
            key: "analog"
            intro: stage.intro
            introDy: 40
            AnalogClock {
                time: analogClock.date
                size: WidgetSettings.v("analogSize")
                seconds: WidgetSettings.v("analogSeconds")
                numbers: WidgetSettings.v("analogNumbers")
                ticks: WidgetSettings.v("analogTicks")
                ink: analogW.ink
                inkDim: analogW.inkDim
                inkFaint: analogW.inkFaint
                accent: analogW.accent
            }
        }

        // ── calendar + events ────────────────────────────────
        DeskWidget {
            id: calendarW
            key: "calendar"
            intro: stage.introCal
            introDx: 60
            introDy: 0
            Row {
                spacing: 18
                Column {
                    width: WidgetSettings.v("calendarWidth")
                    spacing: 8
                    Row {
                        spacing: 10
                        Txt { text: Qt.locale("en_US").toString(clock.date, "dddd"); color: calendarW.inkDim; font.pixelSize: Theme.fontSmall }
                        Txt { text: Qt.formatDate(clock.date, "yyyy-MM-dd"); color: calendarW.inkDim; font.pixelSize: Theme.fontSmall }
                    }
                    MonthGrid {
                        width: parent.width
                        today: clock.date
                        weekNumbers: WidgetSettings.v("calendarWeekNumbers")
                        cell: Math.floor(WidgetSettings.v("calendarWidth") / (WidgetSettings.v("calendarWeekNumbers") ? 8 : 7))
                        fontSize: Theme.fontSmall
                        textColor: calendarW.ink
                        dimColor: calendarW.inkDim
                        faintColor: calendarW.inkFaint
                        accentColor: calendarW.accent
                        accentInkColor: calendarW.accentInk
                        hoverColor: calendarW.hoverTint
                    }
                }
                Column {
                    visible: WidgetSettings.v("calendarEvents")
                    width: Theme.eventsWidth
                    spacing: 4
                    topPadding: 34
                    Txt {
                        width: parent.width
                        text: Qt.locale("en_US").toString(clock.date, "dddd d MMMM")
                        color: calendarW.ink
                        font.weight: Font.Bold
                        font.pixelSize: Theme.fontItem
                        wrapMode: Text.Wrap
                        elide: Text.ElideNone
                    }
                    Txt { text: "No events."; color: calendarW.inkDim; font.pixelSize: Theme.fontSmall }
                }
            }
        }

        // ── visualizer ───────────────────────────────────────
        DeskWidget {
            id: visualizerW
            key: "visualizer"
            backdropAllowed: false
            Visualizer {
                enabled_: visualizerW.shown
                barColor: visualizerW.accent
                width: Math.round(stage.width * WidgetSettings.v("visualizerWidth") / 100)
                height: WidgetSettings.v("visualizerHeight")
            }
        }

        // ── greeting ─────────────────────────────────────────
        DeskWidget {
            id: greetingW
            key: "greeting"
            intro: stage.intro
            readonly property real sc: WidgetSettings.v("greetingScale")
            readonly property string name: {
                const n = (WidgetSettings.v("greetingName") ?? "").trim();
                if (n !== "") return n;
                const u = SystemStats.user;
                return u.charAt(0).toUpperCase() + u.slice(1);
            }
            Column {
                spacing: 4 * greetingW.sc
                Txt {
                    readonly property int h: clock.date.getHours()
                    text: (h < 5 ? "Good night" : h < 12 ? "Good morning" : h < 18 ? "Good afternoon" : h < 22 ? "Good evening" : "Good night")
                          + ", " + greetingW.name
                    color: greetingW.ink
                    font.pixelSize: Math.round(34 * greetingW.sc)
                    font.weight: Font.DemiBold
                    elide: Text.ElideNone
                }
                Txt {
                    visible: WidgetSettings.v("greetingDate")
                    text: Qt.locale("en_US").toString(clock.date, "dddd, d MMMM yyyy")
                    color: greetingW.accent
                    font.pixelSize: Math.round(16 * greetingW.sc)
                    elide: Text.ElideNone
                }
            }
        }

        // ── media ────────────────────────────────────────────
        DeskWidget {
            id: mediaW
            key: "media"
            intro: stage.introCal
            available: !WidgetSettings.v("mediaAutoHide") || Media.player !== null
            readonly property real sc: WidgetSettings.v("mediaScale")
            Row {
                spacing: 14 * mediaW.sc
                ClippingRectangle {
                    visible: WidgetSettings.v("mediaArt")
                    anchors.verticalCenter: parent.verticalCenter
                    width: 72 * mediaW.sc
                    height: width
                    radius: Theme.radiusTile * mediaW.sc
                    color: mediaW.hoverTint
                    Image {
                        anchors.fill: parent
                        source: Media.art
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                        visible: Media.art !== ""
                    }
                    Icon {
                        anchors.centerIn: parent
                        visible: Media.art === ""
                        name: "album"
                        size: 34 * mediaW.sc
                        color: mediaW.inkDim
                    }
                }
                Column {
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 3 * mediaW.sc
                    Txt {
                        width: Math.min(implicitWidth, 240 * mediaW.sc)
                        text: Media.title
                        color: mediaW.ink
                        font.pixelSize: Math.round(15 * mediaW.sc)
                        font.weight: Font.DemiBold
                    }
                    Txt {
                        width: Math.min(implicitWidth, 240 * mediaW.sc)
                        text: Media.artist
                        color: mediaW.inkDim
                        font.pixelSize: Math.round(13 * mediaW.sc)
                    }
                    Row {
                        visible: WidgetSettings.v("mediaControls")
                        topPadding: 4 * mediaW.sc
                        spacing: 4 * mediaW.sc
                        CardButton {
                            host: mediaW; size: 30 * mediaW.sc; icon: "skip_previous"
                            onClicked: Media.player?.previous()
                        }
                        CardButton {
                            host: mediaW; size: 30 * mediaW.sc; primary: true
                            icon: Media.playing ? "pause" : "play_arrow"
                            onClicked: Media.player?.togglePlaying()
                        }
                        CardButton {
                            host: mediaW; size: 30 * mediaW.sc; icon: "skip_next"
                            onClicked: Media.player?.next()
                        }
                    }
                }
            }
        }

        // ── system ───────────────────────────────────────────
        DeskWidget {
            id: systemW
            key: "system"
            intro: stage.introCal
            readonly property real sc: WidgetSettings.v("systemScale")
            Row {
                spacing: 16 * systemW.sc
                Ring {
                    visible: WidgetSettings.v("systemCpu")
                    host: systemW; size: 64 * systemW.sc
                    value: SystemStats.cpu
                    valueText: Math.round(SystemStats.cpu * 100) + "%"
                    label: "CPU"
                }
                Ring {
                    visible: WidgetSettings.v("systemRam")
                    host: systemW; size: 64 * systemW.sc
                    value: SystemStats.memTotal > 0 ? SystemStats.memUsed / SystemStats.memTotal : 0
                    valueText: Math.round(value * 100) + "%"
                    label: "RAM"
                }
                Ring {
                    visible: WidgetSettings.v("systemTemp")
                    host: systemW; size: 64 * systemW.sc
                    value: isNaN(SystemStats.cpuTemp) ? 0 : SystemStats.cpuTemp / 100
                    valueText: SystemStats.tempText
                    label: "TEMP"
                }
            }
        }

        // ── weather ──────────────────────────────────────────
        DeskWidget {
            id: weatherW
            key: "weather"
            intro: stage.intro
            readonly property real sc: WidgetSettings.v("weatherScale")
            readonly property bool fahrenheit: WidgetSettings.v("weatherFahrenheit")
            Row {
                spacing: 14 * weatherW.sc
                Icon {
                    anchors.verticalCenter: parent.verticalCenter
                    name: Weather.icon
                    size: 54 * weatherW.sc
                    color: weatherW.accent
                }
                Column {
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 2 * weatherW.sc
                    Row {
                        spacing: 10 * weatherW.sc
                        Txt {
                            anchors.baseline: descText.baseline
                            text: Weather.loaded ? Weather.temp(Weather.tempC, weatherW.fahrenheit) : (Weather.failed ? "–" : "…")
                            color: weatherW.ink
                            font.pixelSize: Math.round(40 * weatherW.sc)
                            font.weight: Font.DemiBold
                            elide: Text.ElideNone
                        }
                        Txt {
                            id: descText
                            text: Weather.loaded ? Weather.desc : (Weather.failed ? "No weather" : "Loading")
                            color: weatherW.inkDim
                            font.pixelSize: Math.round(15 * weatherW.sc)
                            elide: Text.ElideNone
                        }
                    }
                    Txt {
                        visible: WidgetSettings.v("weatherDetails") && Weather.loaded
                        text: "↑ " + Weather.temp(Weather.maxC, weatherW.fahrenheit)
                              + "  ↓ " + Weather.temp(Weather.minC, weatherW.fahrenheit)
                              + "  ·  " + Weather.humidity + "%"
                              + (Weather.place !== "" ? "  ·  " + Weather.place : "")
                        color: weatherW.inkFaint
                        font.pixelSize: Math.round(12 * weatherW.sc)
                        elide: Text.ElideNone
                    }
                }
            }
        }
    }
}
