import QtQuick
import Quickshell
import Quickshell.Io
import ".."
import "../widgets/watch"

// Etappe 7's analog watch face stays as the "jetzige Uhr", extended below
// with Wetter + Monatskalender per Nutzerauftrag. Weather/geolocation
// logic ported verbatim from bars/floating/center/CalendarWeatherPopup.qml
// (already proven there: Open-Meteo, ip-api.com fallback geolocation,
// Monday-start week, offline-keeps-last-value) -- only the color/text
// styling changed, to match this bar's LCD look (Theme.surfaceInk +
// opacity instead of a separate muted-text role, no font.family override,
// same as NetworkMenu/PowerMenu).
Item {
    id: root

    property var current: null // {temp, feels, wind, precipProb, code}
    property var daily: [] // [{date, code, max, min}]

    function _wmoLabel(code) {
        const map = {
            0: "KLAR", 1: "MEIST KLAR", 2: "TEILW. BEWÖLKT", 3: "BEDECKT",
            45: "NEBEL", 48: "NEBEL",
            51: "NIESEL", 53: "NIESEL", 55: "NIESEL",
            56: "GEFR. NIESEL", 57: "GEFR. NIESEL",
            61: "LEICHTER REGEN", 63: "REGEN", 65: "STARKER REGEN",
            66: "GEFR. REGEN", 67: "GEFR. REGEN",
            71: "LEICHTER SCHNEE", 73: "SCHNEE", 75: "STARKER SCHNEE",
            77: "SCHNEEGRIESEL",
            80: "REGENSCHAUER", 81: "REGENSCHAUER", 82: "STARKE SCHAUER",
            85: "SCHNEESCHAUER", 86: "SCHNEESCHAUER",
            95: "GEWITTER", 96: "GEWITTER/HAGEL", 99: "GEWITTER/HAGEL"
        };
        return map[code] || "UNBEKANNT";
    }

    function _refreshLocationThenWeather() {
        if (Config.weatherLat !== 0 || Config.weatherLon !== 0)
            root._fetchWeather(Config.weatherLat, Config.weatherLon);
        else
            geoProc.running = true;
    }

    Process {
        id: geoProc
        command: ["curl", "-s", "--max-time", "6", "http://ip-api.com/json/?fields=lat,lon,city"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const d = JSON.parse(text);
                    if (d.lat !== undefined) {
                        Config.cacheAutoLocation(d.lat, d.lon, d.city || "");
                        root._fetchWeather(d.lat, d.lon);
                    }
                } catch (e) { /* offline oder blockiert -- Platzhalter bleibt stehen */ }
            }
        }
    }

    Process {
        id: weatherProc
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const d = JSON.parse(text);
                    root.current = {
                        temp: Math.round(d.current.temperature_2m),
                        feels: Math.round(d.current.apparent_temperature),
                        wind: Math.round(d.current.wind_speed_10m),
                        precipProb: d.current.precipitation_probability,
                        code: d.current.weather_code
                    };
                    const days = [];
                    for (let i = 0; i < d.daily.time.length; i++) {
                        days.push({
                            date: d.daily.time[i],
                            code: d.daily.weather_code[i],
                            max: Math.round(d.daily.temperature_2m_max[i]),
                            min: Math.round(d.daily.temperature_2m_min[i])
                        });
                    }
                    root.daily = days;
                } catch (e) { /* letzten Stand behalten */ }
            }
        }
    }

    function _fetchWeather(lat, lon) {
        const url = "https://api.open-meteo.com/v1/forecast?latitude=" + lat + "&longitude=" + lon + "&current=temperature_2m,apparent_temperature,weather_code,wind_speed_10m,precipitation_probability" + "&daily=weather_code,temperature_2m_max,temperature_2m_min" + "&timezone=auto&forecast_days=5";
        weatherProc.command = ["curl", "-s", "--max-time", "8", url];
        weatherProc.running = true;
    }

    Component.onCompleted: root._refreshLocationThenWeather()

    Timer {
        interval: 25 * 60 * 1000
        running: true
        repeat: true
        onTriggered: root._refreshLocationThenWeather()
    }

    readonly property var weekdaysShort: ["MO", "DI", "MI", "DO", "FR", "SA", "SO"]
    readonly property var monthNames: ["JANUAR", "FEBRUAR", "MÄRZ", "APRIL", "MAI", "JUNI", "JULI", "AUGUST", "SEPTEMBER", "OKTOBER", "NOVEMBER", "DEZEMBER"]

    readonly property date today: new Date()
    property int viewYear: today.getFullYear()
    property int viewMonth: today.getMonth()
    readonly property bool viewingCurrentMonth: root.viewYear === today.getFullYear() && root.viewMonth === today.getMonth()

    function prevMonth() {
        if (root.viewMonth === 0) {
            root.viewMonth = 11;
            root.viewYear -= 1;
        } else
            root.viewMonth -= 1;
    }
    function nextMonth() {
        if (root.viewMonth === 11) {
            root.viewMonth = 0;
            root.viewYear += 1;
        } else
            root.viewMonth += 1;
    }
    function backToToday() {
        root.viewYear = root.today.getFullYear();
        root.viewMonth = root.today.getMonth();
    }
    function _monthDays() {
        const y = root.viewYear, m = root.viewMonth;
        const firstDow = (new Date(y, m, 1).getDay() + 6) % 7; // Mo=0
        const daysInMonth = new Date(y, m + 1, 0).getDate();
        const cells = [];
        for (let i = 0; i < firstDow; i++)
            cells.push(null);
        for (let d = 1; d <= daysInMonth; d++)
            cells.push(d);
        return cells;
    }

    Flickable {
        anchors.fill: parent
        clip: true
        contentHeight: col.implicitHeight
        boundsBehavior: Flickable.StopAtBounds

        Column {
            id: col
            width: parent.width
            spacing: 8

            AnalogClock {
                anchors.horizontalCenter: parent.horizontalCenter
                // Same transient-negative-size guard the previous
                // centerIn-based layout needed (PopupShell's contentArea
                // briefly has zero/negative height while collapsed) --
                // here it's col.width that can be 0 for a frame instead.
                size: Math.max(1, Math.min(col.width, 96))
            }

            Rectangle {
                width: parent.width
                height: 1
                color: Theme.bevelDark
            }

            Column {
                width: parent.width
                spacing: 3

                Row {
                    width: parent.width
                    spacing: 6

                    Text {
                        text: root.current ? root.current.temp + "°C" : "…"
                        color: Theme.surfaceInk
                        font.pixelSize: 18
                        font.bold: true
                        anchors.verticalCenter: parent.verticalCenter
                    }
                    Text {
                        text: root.current ? root._wmoLabel(root.current.code) : "LADE WETTER…"
                        color: Theme.surfaceInk
                        opacity: 0.7
                        font.pixelSize: 9
                        font.letterSpacing: 0.5
                        elide: Text.ElideRight
                        width: parent.width - 60
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }
                Text {
                    visible: root.current !== null
                    text: root.current ? ("GEFÜHLT " + root.current.feels + "°C · WIND " + root.current.wind + " KM/H · REGEN " + root.current.precipProb + "%") : ""
                    color: Theme.surfaceInk
                    opacity: 0.5
                    font.pixelSize: 8
                    font.letterSpacing: 0.5
                }

                Row {
                    width: parent.width
                    spacing: 4
                    topPadding: 4

                    Repeater {
                        model: root.daily.slice(1, 5)
                        delegate: Column {
                            id: dayCol
                            required property var modelData
                            width: (col.width - 3 * 4) / 4
                            spacing: 2
                            Text {
                                width: parent.width
                                horizontalAlignment: Text.AlignHCenter
                                text: root.weekdaysShort[(new Date(dayCol.modelData.date).getDay() + 6) % 7]
                                color: Theme.surfaceInk
                                opacity: 0.5
                                font.pixelSize: 8
                            }
                            Text {
                                width: parent.width
                                horizontalAlignment: Text.AlignHCenter
                                text: dayCol.modelData.max + "°/" + dayCol.modelData.min + "°"
                                color: Theme.surfaceInk
                                font.pixelSize: 9
                                font.bold: true
                            }
                        }
                    }
                }
            }

            Rectangle {
                width: parent.width
                height: 1
                color: Theme.bevelDark
            }

            Column {
                width: parent.width
                spacing: 6

                Row {
                    width: parent.width

                    Text {
                        width: 20
                        horizontalAlignment: Text.AlignHCenter
                        text: "<"
                        color: Theme.surfaceInk
                        opacity: prevArea.containsMouse ? 1 : 0.5
                        font.pixelSize: 11
                        MouseArea {
                            id: prevArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.prevMonth()
                        }
                    }
                    Text {
                        width: parent.width - 40
                        horizontalAlignment: Text.AlignHCenter
                        text: root.monthNames[root.viewMonth] + " " + root.viewYear
                        color: Theme.surfaceInk
                        opacity: root.viewingCurrentMonth ? 0.6 : 1
                        font.pixelSize: 9
                        font.letterSpacing: 0.5
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.backToToday()
                        }
                    }
                    Text {
                        width: 20
                        horizontalAlignment: Text.AlignHCenter
                        text: ">"
                        color: Theme.surfaceInk
                        opacity: nextArea.containsMouse ? 1 : 0.5
                        font.pixelSize: 11
                        MouseArea {
                            id: nextArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.nextMonth()
                        }
                    }
                }

                Grid {
                    width: parent.width
                    columns: 7
                    columnSpacing: Math.max(0, (parent.width - 7 * 26) / 6)
                    rowSpacing: 4

                    Repeater {
                        model: root.weekdaysShort
                        delegate: Text {
                            required property string modelData
                            width: 26
                            horizontalAlignment: Text.AlignHCenter
                            text: modelData
                            color: Theme.surfaceInk
                            opacity: 0.5
                            font.pixelSize: 8
                        }
                    }

                    Repeater {
                        model: root._monthDays()
                        delegate: Item {
                            id: dayCell
                            required property var modelData
                            readonly property bool isToday: root.viewingCurrentMonth && dayCell.modelData === root.today.getDate()
                            width: 26
                            height: 22

                            Rectangle {
                                anchors.centerIn: parent
                                width: 18
                                height: 18
                                radius: 9
                                visible: dayCell.isToday
                                color: Theme.accent
                            }
                            Text {
                                anchors.centerIn: parent
                                visible: dayCell.modelData !== null
                                text: dayCell.modelData || ""
                                color: dayCell.isToday ? Theme.accentInk : Theme.surfaceInk
                                opacity: dayCell.isToday ? 1 : 0.8
                                font.pixelSize: 9
                            }
                        }
                    }
                }
            }
        }
    }
}
