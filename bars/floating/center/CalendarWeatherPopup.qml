import QtQuick
import QtQuick.Layouts
import Quickshell.Io
import ".."

// Clock click target (spec 4 "Kalender & Wetter"): big clock + ISO date with
// weekday, a navigable Monday-start month calendar, and current + 3-day
// weather from Open-Meteo. Weather/geolocation logic ported verbatim from
// quickbar/WeatherTab.qml (already proven: Monday-start week, German
// weekday abbreviations, 15-30min refresh, offline-keeps-last-value). Added
// on top: a live clock, and month prev/next/today-navigation the original
// tab didn't have (this popup shows a fixed month grid; quickbar's tab only
// ever showed the current month).
PopupBase {
    id: popup
    popupWidth: 300
    popupHeight: col.implicitHeight + 20

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
            popup._fetchWeather(Settings.weatherLat, Settings.weatherLon);
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
                        popup._fetchWeather(d.lat, d.lon);
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
                    popup.current = {
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
                    popup.daily = days;
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

    Component.onCompleted: popup._refreshLocationThenWeather()

    Timer {
        interval: 25 * 60 * 1000
        running: true
        repeat: true
        onTriggered: popup._refreshLocationThenWeather()
    }

    // -- live clock --
    property date now: new Date()
    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: popup.now = new Date()
    }
    function _pad(n) { return n < 10 ? "0" + n : "" + n; }

    readonly property var weekdaysShort: ["Mo", "Di", "Mi", "Do", "Fr", "Sa", "So"]
    readonly property var weekdaysLong: ["Montag", "Dienstag", "Mittwoch", "Donnerstag", "Freitag", "Samstag", "Sonntag"]
    readonly property var monthNames: ["Januar", "Februar", "März", "April", "Mai", "Juni", "Juli", "August", "September", "Oktober", "November", "Dezember"]

    readonly property date today: new Date()
    property int viewYear: today.getFullYear()
    property int viewMonth: today.getMonth()

    function prevMonth() {
        if (popup.viewMonth === 0) { popup.viewMonth = 11; popup.viewYear -= 1; }
        else popup.viewMonth -= 1;
    }
    function nextMonth() {
        if (popup.viewMonth === 11) { popup.viewMonth = 0; popup.viewYear += 1; }
        else popup.viewMonth += 1;
    }
    function backToToday() {
        popup.viewYear = popup.today.getFullYear();
        popup.viewMonth = popup.today.getMonth();
    }

    function _monthDays() {
        const y = popup.viewYear, m = popup.viewMonth;
        const firstDow = (new Date(y, m, 1).getDay() + 6) % 7; // Mon=0
        const daysInMonth = new Date(y, m + 1, 0).getDate();
        const cells = [];
        for (let i = 0; i < firstDow; i++) cells.push(null);
        for (let d = 1; d <= daysInMonth; d++) cells.push(d);
        return cells;
    }
    readonly property bool viewingCurrentMonth: popup.viewYear === today.getFullYear() && popup.viewMonth === today.getMonth()

    ColumnLayout {
        id: col
        width: popup.popupWidth - 20
        spacing: 16

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 2

            Text {
                text: popup._pad(popup.now.getHours()) + ":" + popup._pad(popup.now.getMinutes())
                color: Theme.text
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSizeBigClock
                font.bold: true
            }
            Text {
                text: popup.now.getFullYear() + "-" + popup._pad(popup.now.getMonth() + 1) + "-" + popup._pad(popup.now.getDate()) +
                      " · " + popup.weekdaysLong[(popup.now.getDay() + 6) % 7]
                color: Theme.textMuted
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSizeSmall
            }
        }

        Rectangle { Layout.fillWidth: true; height: 1; color: Qt.alpha(Theme.textMuted, 0.2) }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 4

            Text {
                text: popup.current ? popup.current.temp + "°C" : "…"
                color: Theme.text
                font.family: Theme.fontFamily
                font.pixelSize: 22
                font.bold: true
            }
            Text {
                text: popup.current ? popup._wmoLabel(popup.current.code) : "Lade Wetter…"
                color: Theme.textMuted
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSizeSmall
            }
            Text {
                visible: popup.current !== null
                text: popup.current ? ("Gefühlt " + popup.current.feels + "°C · Wind " + popup.current.wind + " km/h · Regen " + popup.current.precipProb + "%") : ""
                color: Theme.textMuted
                font.family: Theme.fontFamily
                font.pixelSize: 10
            }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 4

            Repeater {
                model: popup.daily.slice(1, 5)
                delegate: ColumnLayout {
                    id: dayCol
                    required property var modelData
                    Layout.fillWidth: true
                    spacing: 3
                    Text {
                        Layout.alignment: Qt.AlignHCenter
                        text: Qt.formatDate(new Date(dayCol.modelData.date), "ddd")
                        color: Theme.textMuted
                        font.family: Theme.fontFamily
                        font.pixelSize: 10
                    }
                    Text {
                        Layout.alignment: Qt.AlignHCenter
                        text: dayCol.modelData.max + "°/" + dayCol.modelData.min + "°"
                        color: Theme.text
                        font.family: Theme.fontFamily
                        font.pixelSize: 11
                        font.bold: true
                    }
                }
            }
        }

        Rectangle { Layout.fillWidth: true; height: 1; color: Qt.alpha(Theme.textMuted, 0.2) }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 6

            RowLayout {
                Layout.fillWidth: true

                Rectangle {
                    Layout.preferredWidth: 18; Layout.preferredHeight: 18
                    radius: 5
                    color: prevArea.containsMouse ? Qt.alpha(Theme.textMuted, 0.15) : "transparent"
                    Icon { anchors.centerIn: parent; name: "chevronLeft"; size: 11; tint: Theme.textMuted }
                    MouseArea { id: prevArea; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: popup.prevMonth() }
                }

                Text {
                    Layout.fillWidth: true
                    horizontalAlignment: Text.AlignHCenter
                    text: popup.monthNames[popup.viewMonth] + " " + popup.viewYear
                    color: popup.viewingCurrentMonth ? Theme.textMuted : Theme.text
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSizeSmall

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: popup.backToToday()
                    }
                }

                Rectangle {
                    Layout.preferredWidth: 18; Layout.preferredHeight: 18
                    radius: 5
                    color: nextArea.containsMouse ? Qt.alpha(Theme.textMuted, 0.15) : "transparent"
                    Icon { anchors.centerIn: parent; name: "chevronRight"; size: 11; tint: Theme.textMuted }
                    MouseArea { id: nextArea; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: popup.nextMonth() }
                }
            }

            GridLayout {
                Layout.fillWidth: true
                columns: 7
                rowSpacing: 4
                columnSpacing: 2

                Repeater {
                    model: popup.weekdaysShort
                    delegate: Text {
                        required property string modelData
                        Layout.fillWidth: true
                        horizontalAlignment: Text.AlignHCenter
                        text: modelData
                        color: Theme.textMuted
                        font.family: Theme.fontFamily
                        font.pixelSize: 10
                    }
                }

                Repeater {
                    model: popup._monthDays()
                    delegate: Item {
                        id: dayCell
                        required property var modelData
                        readonly property bool isToday: popup.viewingCurrentMonth && dayCell.modelData === popup.today.getDate()
                        Layout.fillWidth: true
                        Layout.preferredHeight: 22

                        Rectangle {
                            anchors.centerIn: parent
                            width: 20; height: 20; radius: 10
                            visible: dayCell.isToday
                            color: Theme.activeHighlight
                            border.width: 1
                            border.color: Theme.activeBorder
                        }
                        Text {
                            anchors.centerIn: parent
                            visible: dayCell.modelData !== null
                            text: dayCell.modelData || ""
                            color: dayCell.isToday ? Theme.text : Theme.textMuted
                            font.family: Theme.fontFamily
                            font.pixelSize: 11
                        }
                    }
                }
            }
        }
    }
}
