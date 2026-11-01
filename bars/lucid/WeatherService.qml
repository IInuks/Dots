pragma Singleton
import QtQuick

// Open-Meteo (no API key) instead of wttr.in -- both were fine per spec,
// Open-Meteo's JSON is far less fragile to parse than wttr.in's format
// strings. Two requests: geocode Config.weatherLocation once (re-run
// whenever it changes), then poll the forecast endpoint for that lat/lon.
QtObject {
    id: root

    property bool ready: false
    property string error: ""
    property string resolvedName: ""
    property real latitude: NaN
    property real longitude: NaN

    property real temperature: NaN
    property int weatherCode: -1
    property string description: ""
    property string iconGlyph: "cloud"

    readonly property bool locationConfigured: Config.weatherLocation.length > 0

    onLocationConfiguredChanged: if (locationConfigured) _geocode()
    Component.onCompleted: if (locationConfigured) _geocode()

    function _geocode() {
        root.error = "";
        const url = "https://geocoding-api.open-meteo.com/v1/search?count=1&language=de&format=json&name=" + encodeURIComponent(Config.weatherLocation);
        const xhr = new XMLHttpRequest();
        xhr.onreadystatechange = function () {
            if (xhr.readyState !== XMLHttpRequest.DONE)
                return;
            if (xhr.status !== 200) {
                root.error = "Geocoding fehlgeschlagen (" + xhr.status + ")";
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
            root.resolvedName = r.name + (r.country ? ", " + r.country : "");
            root.latitude = r.latitude;
            root.longitude = r.longitude;
            root._fetchForecast();
        };
        xhr.open("GET", url);
        xhr.send();
    }

    function _fetchForecast() {
        if (isNaN(root.latitude) || isNaN(root.longitude))
            return;
        const url = "https://api.open-meteo.com/v1/forecast?latitude=" + root.latitude + "&longitude=" + root.longitude + "&current_weather=true";
        const xhr = new XMLHttpRequest();
        xhr.onreadystatechange = function () {
            if (xhr.readyState !== XMLHttpRequest.DONE)
                return;
            if (xhr.status !== 200) {
                root.error = "Wetter-Abfrage fehlgeschlagen (" + xhr.status + ")";
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
            root.ready = true;
            root.error = "";
        };
        xhr.open("GET", url);
        xhr.send();
    }

    // WMO weather codes (Open-Meteo's `weathercode`), condensed to the
    // ranges actually documented by Open-Meteo.
    function _describeCode(code) {
        const table = {
            0: { text: "Klar", icon: "clear_day" },
            1: { text: "Überwiegend klar", icon: "partly_cloudy_day" },
            2: { text: "Teils bewölkt", icon: "partly_cloudy_day" },
            3: { text: "Bedeckt", icon: "cloud" },
            45: { text: "Nebel", icon: "foggy" },
            48: { text: "Nebel (Reif)", icon: "foggy" },
            51: { text: "Leichter Nieselregen", icon: "rainy" },
            53: { text: "Nieselregen", icon: "rainy" },
            55: { text: "Starker Nieselregen", icon: "rainy" },
            61: { text: "Leichter Regen", icon: "rainy" },
            63: { text: "Regen", icon: "rainy" },
            65: { text: "Starker Regen", icon: "rainy" },
            71: { text: "Leichter Schneefall", icon: "weather_snowy" },
            73: { text: "Schneefall", icon: "weather_snowy" },
            75: { text: "Starker Schneefall", icon: "weather_snowy" },
            80: { text: "Regenschauer", icon: "rainy" },
            81: { text: "Regenschauer", icon: "rainy" },
            82: { text: "Heftige Regenschauer", icon: "rainy" },
            85: { text: "Schneeschauer", icon: "weather_snowy" },
            86: { text: "Schneeschauer", icon: "weather_snowy" },
            95: { text: "Gewitter", icon: "thunderstorm" },
            96: { text: "Gewitter mit Hagel", icon: "thunderstorm" },
            99: { text: "Gewitter mit Hagel", icon: "thunderstorm" }
        };
        return table[code] || { text: "Unbekannt", icon: "cloud" };
    }

    property Timer _refresh: Timer {
        interval: 15 * 60 * 1000
        running: root.locationConfigured
        repeat: true
        onTriggered: root._fetchForecast()
    }
}
