pragma Singleton
import QtQuick

// Current weather for the "weather" widget (bar prompt section 4), Wien
// (Config.weatherCity) via Open-Meteo -- no API key, same source and
// geocode-then-forecast approach bars/lucid/WeatherService.qml already
// proved on this system, adapted to ricev2's own field name (Config.
// weatherCity, not weatherLocation) and its own poll cadence ("Wetter alle
// 10 min", bar prompt section 8 -- lucid used 15 min, not reused here).
// Config.weatherSource only ever names "open-meteo" today, so there's no
// second backend to branch on.
//
// iconGlyph is a Nerd-Font (nf-md-*) codepoint straight from the bar
// prompt's own table (section 4), not a named icon like lucid's -- ricev2
// renders icons as plain codepoints via Style.iconFont everywhere else
// (see ClockWidget.qml et al.), so widgets expect a literal glyph string
// here, not an icon-name lookup. \u{...} codepoint escapes are needed (not
// plain \uXXXX) because these sit above the BMP -- same syntax already
// proven in this repo by bars/blobs/components/ClockBlob.qml.
QtObject {
    id: root

    property bool ready: false
    property string error: ""
    property real latitude: NaN
    property real longitude: NaN

    property real temperature: NaN
    property int weatherCode: -1
    property string description: ""
    property string iconGlyph: "\u{F0590}" // bewölkt, sane default until first fetch

    // Daily forecast for the weather dropdown (menus prompt 1.5) --
    // [{date, dayLabel, icon, tempMax, tempMin, rain, wind}], today first.
    property var dailyForecast: []

    Component.onCompleted: _geocode()

    function _geocode() {
        root.error = "";
        const city = Config.weatherCity;
        if (!city || city.length === 0)
            return;
        const url = "https://geocoding-api.open-meteo.com/v1/search?count=1&language=de&format=json&name=" + encodeURIComponent(city);
        const xhr = new XMLHttpRequest();
        xhr.onreadystatechange = function () {
            if (xhr.readyState !== XMLHttpRequest.DONE)
                return;
            if (xhr.status !== 200) {
                root._fail("Geocoding fehlgeschlagen (" + xhr.status + ")");
                return;
            }
            let data;
            try {
                data = JSON.parse(xhr.responseText);
            } catch (e) {
                root.error = "Geocoding: ungültige Antwort";
                return;
            }
            const r = data.results && data.results[0];
            if (!r) {
                root.error = "Ort nicht gefunden";
                return;
            }
            root.latitude = r.latitude;
            root.longitude = r.longitude;
            root._fetchForecast();
        };
        xhr.open("GET", url);
        xhr.send();
    }

    // Network/DNS often isn't up yet when mango's exec-once starts the bar,
    // so a failed request retries every 30s instead of waiting for the
    // 10-min refresh (which could never recover a failed geocode anyway).
    function _fail(msg) {
        root.error = msg;
        console.warn("WeatherService:", msg);
        root._retry.restart();
    }

    function _update() {
        if (isNaN(root.latitude) || isNaN(root.longitude))
            root._geocode();
        else
            root._fetchForecast();
    }

    function _fetchForecast() {
        if (isNaN(root.latitude) || isNaN(root.longitude))
            return;
        const url = "https://api.open-meteo.com/v1/forecast?latitude=" + root.latitude + "&longitude=" + root.longitude
            + "&current_weather=true"
            + "&daily=weathercode,temperature_2m_max,temperature_2m_min,precipitation_sum,windspeed_10m_max"
            + "&timezone=auto";
        const xhr = new XMLHttpRequest();
        xhr.onreadystatechange = function () {
            if (xhr.readyState !== XMLHttpRequest.DONE)
                return;
            if (xhr.status !== 200) {
                root._fail("Wetter-Abfrage fehlgeschlagen (" + xhr.status + ")");
                return;
            }
            let data;
            try {
                data = JSON.parse(xhr.responseText);
            } catch (e) {
                root.error = "Wetter: ungültige Antwort";
                return;
            }
            const cw = data.current_weather;
            if (!cw) {
                root.error = "Wetter: keine Daten";
                return;
            }
            root.temperature = cw.temperature;
            root.weatherCode = cw.weathercode;
            const mapped = root._describeCode(cw.weathercode);
            root.description = mapped.text;
            root.iconGlyph = mapped.icon;
            root.dailyForecast = root._buildDaily(data.daily);
            root.ready = true;
            root.error = "";
        };
        xhr.open("GET", url);
        xhr.send();
    }

    // Menus prompt 1.5's forecast cards: day label, icon, high/low, rain
    // (>=0.1mm), wind. Open-Meteo's `daily` block gives one value per day.
    function _buildDaily(daily) {
        if (!daily || !daily.time)
            return [];
        const days = [];
        for (let i = 0; i < daily.time.length; i++) {
            const date = new Date(daily.time[i]);
            const mapped = root._describeCode(daily.weathercode[i]);
            days.push({
                date: daily.time[i],
                dayLabel: Qt.formatDate(date, "ddd"),
                icon: mapped.icon,
                tempMax: Math.round(daily.temperature_2m_max[i]),
                tempMin: Math.round(daily.temperature_2m_min[i]),
                rain: daily.precipitation_sum[i],
                wind: Math.round(daily.windspeed_10m_max[i])
            });
        }
        return days;
    }

    // WMO weather codes -> the bar prompt's own category table (section 4):
    // Gewitter F067E, Schneesturm F0F36, Schnee F0598, Graupel F067F,
    // Starkregen F0596, Regen F0597, Nebel F0591, teils bewölkt F0595,
    // bewölkt F0590, sonnig/klar F0599. The prompt names categories, not a
    // full WMO table, so codes are bucketed into those ten by severity
    // (freezing rain/drizzle -> Graupel, the closest of the ten to "icy
    // rain").
    function _describeCode(code) {
        const table = {
            0: { text: "Klar", icon: "\u{F0599}" },
            1: { text: "Überwiegend klar", icon: "\u{F0595}" },
            2: { text: "Teils bewölkt", icon: "\u{F0595}" },
            3: { text: "Bedeckt", icon: "\u{F0590}" },
            45: { text: "Nebel", icon: "\u{F0591}" },
            48: { text: "Nebel (Reif)", icon: "\u{F0591}" },
            51: { text: "Leichter Nieselregen", icon: "\u{F0597}" },
            53: { text: "Nieselregen", icon: "\u{F0597}" },
            55: { text: "Starker Nieselregen", icon: "\u{F0596}" },
            56: { text: "Gefrierender Nieselregen", icon: "\u{F067F}" },
            57: { text: "Gefrierender Nieselregen", icon: "\u{F067F}" },
            61: { text: "Leichter Regen", icon: "\u{F0597}" },
            63: { text: "Regen", icon: "\u{F0597}" },
            65: { text: "Starker Regen", icon: "\u{F0596}" },
            66: { text: "Gefrierender Regen", icon: "\u{F067F}" },
            67: { text: "Gefrierender Regen", icon: "\u{F067F}" },
            71: { text: "Leichter Schneefall", icon: "\u{F0598}" },
            73: { text: "Schneefall", icon: "\u{F0598}" },
            75: { text: "Starker Schneefall", icon: "\u{F0F36}" },
            77: { text: "Schneegriesel", icon: "\u{F0598}" },
            80: { text: "Regenschauer", icon: "\u{F0597}" },
            81: { text: "Regenschauer", icon: "\u{F0597}" },
            82: { text: "Heftige Regenschauer", icon: "\u{F0596}" },
            85: { text: "Schneeschauer", icon: "\u{F0598}" },
            86: { text: "Starke Schneeschauer", icon: "\u{F0F36}" },
            95: { text: "Gewitter", icon: "\u{F067E}" },
            96: { text: "Gewitter mit Hagel", icon: "\u{F067E}" },
            99: { text: "Gewitter mit Hagel", icon: "\u{F067E}" }
        };
        return table[code] || { text: "Unbekannt", icon: "\u{F0590}" };
    }

    property Timer _refresh: Timer {
        interval: 10 * 60 * 1000
        running: true
        repeat: true
        onTriggered: root._update()
    }

    property Timer _retry: Timer {
        interval: 30 * 1000
        repeat: false
        onTriggered: root._update()
    }

    // Re-geocode when the city is changed in the settings.
    property Connections _cityWatch: Connections {
        target: Config
        function onWeatherCityChanged() {
            root.latitude = NaN;
            root.longitude = NaN;
            root._geocode();
        }
    }
}
