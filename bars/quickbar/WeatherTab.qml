import QtQuick
import Quickshell
import Quickshell.Io

Flickable {
    id: root
    contentHeight: col.implicitHeight
    clip: true
    boundsBehavior: Flickable.StopAtBounds

    property var current: null // {temp, feels, wind, precipProb, code}
    property var daily: []     // [{date, code, max, min, precipProb}]

    function _wmoLabel(code) {
        const map = {
            0: "Klarer Himmel", 1: "Überwiegend klar", 2: "Teilweise bewölkt", 3: "Bedeckt",
            45: "Nebel", 48: "Nebel (Reif)",
            51: "Nieselregen", 53: "Nieselregen", 55: "Nieselregen (stark)",
            56: "Gefr. Nieselregen", 57: "Gefr. Nieselregen",
            61: "Leichter Regen", 63: "Regen", 65: "Starker Regen",
            66: "Gefrierender Regen", 67: "Gefrierender Regen",
            71: "Leichter Schneefall", 73: "Schneefall", 75: "Starker Schneefall",
            77: "Schneegriesel",
            80: "Regenschauer", 81: "Regenschauer", 82: "Starke Regenschauer",
            85: "Schneeschauer", 86: "Schneeschauer",
            95: "Gewitter", 96: "Gewitter mit Hagel", 99: "Gewitter mit Hagel"
        };
        return map[code] || "Unbekannt";
    }

    function _refreshLocationThenWeather() {
        if (Settings.weatherLat !== 0 || Settings.weatherLon !== 0) {
            root._fetchWeather(Settings.weatherLat, Settings.weatherLon);
        } else {
            geoProc.running = true;
        }
    }

    Process {
        id: geoProc
        command: ["curl", "-s", "--max-time", "6", "http://ip-api.com/json/?fields=lat,lon,city"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const d = JSON.parse(text);
                    if (d.lat !== undefined) {
                        Settings.cacheAutoLocation(d.lat, d.lon, d.city || "");
                        root._fetchWeather(d.lat, d.lon);
                    }
                } catch (e) { /* offline or blocked -- leave placeholder state */ }
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
                            min: Math.round(d.daily.temperature_2m_min[i]),
                            precipProb: d.daily.precipitation_probability_max[i]
                        });
                    }
                    root.daily = days;
                } catch (e) { /* keep previous state on parse failure */ }
            }
        }
    }

    function _fetchWeather(lat, lon) {
        const url = "https://api.open-meteo.com/v1/forecast?latitude=" + lat + "&longitude=" + lon +
            "&current=temperature_2m,apparent_temperature,weather_code,wind_speed_10m,precipitation_probability" +
            "&daily=weather_code,temperature_2m_max,temperature_2m_min,precipitation_probability_max" +
            "&timezone=auto&forecast_days=5";
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

    readonly property var weekdays: ["Mo", "Di", "Mi", "Do", "Fr", "Sa", "So"]
    readonly property date today: new Date()

    function _monthDays() {
        const y = today.getFullYear(), m = today.getMonth();
        const firstDow = (new Date(y, m, 1).getDay() + 6) % 7; // Mon=0
        const daysInMonth = new Date(y, m + 1, 0).getDate();
        const cells = [];
        for (let i = 0; i < firstDow; i++) cells.push(null);
        for (let d = 1; d <= daysInMonth; d++) cells.push(d);
        return cells;
    }

    Column {
        id: col
        width: root.width
        spacing: 16

        Column {
            width: parent.width
            spacing: 4

            Text {
                text: root.current ? root.current.temp + "°C" : "…"
                color: Theme.text
                font.pixelSize: 30
                font.bold: true
            }
            Text {
                text: (root.current ? root._wmoLabel(root.current.code) : "Lade Wetter…") +
                      (Settings.weatherLabel ? " · " + Settings.weatherLabel : "")
                color: Theme.textDim
                font.pixelSize: 12
            }
            Text {
                visible: root.current !== null
                text: root.current ? ("Gefühlt " + root.current.feels + "°C · Wind " + root.current.wind + " km/h · Regen " + root.current.precipProb + "%") : ""
                color: Theme.textDim
                font.pixelSize: 11
            }
        }

        Row {
            width: parent.width
            spacing: 4

            Repeater {
                model: root.daily.slice(1, 5)
                delegate: Column {
                    required property var modelData
                    width: (col.width - 3 * 4) / 4
                    spacing: 3
                    Text {
                        width: parent.width
                        horizontalAlignment: Text.AlignHCenter
                        text: Qt.formatDate(new Date(modelData.date), "ddd")
                        color: Theme.textDim
                        font.pixelSize: 10
                    }
                    Text {
                        width: parent.width
                        horizontalAlignment: Text.AlignHCenter
                        text: modelData.max + "°/" + modelData.min + "°"
                        color: Theme.text
                        font.pixelSize: 11
                        font.bold: true
                    }
                }
            }
        }

        Column {
            width: parent.width
            spacing: 6

            Text {
                text: Qt.formatDate(root.today, "MMMM yyyy")
                color: Theme.textDim
                font.pixelSize: 11
            }

            Grid {
                width: parent.width
                columns: 7
                columnSpacing: (parent.width - 7 * 26) / 6
                rowSpacing: 4

                Repeater {
                    model: root.weekdays
                    delegate: Text {
                        required property string modelData
                        width: 26
                        horizontalAlignment: Text.AlignHCenter
                        text: modelData
                        color: Theme.textDim
                        font.pixelSize: 10
                    }
                }

                Repeater {
                    model: root._monthDays()
                    delegate: Item {
                        required property var modelData
                        width: 26; height: 22
                        Rectangle {
                            anchors.centerIn: parent
                            width: 20; height: 20; radius: 10
                            visible: modelData === root.today.getDate()
                            color: Theme.accent
                        }
                        Text {
                            anchors.centerIn: parent
                            visible: modelData !== null
                            text: modelData || ""
                            color: modelData === root.today.getDate() ? Theme.bg : Theme.text
                            font.pixelSize: 11
                        }
                    }
                }
            }
        }
    }
}
