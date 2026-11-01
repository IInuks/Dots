pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Current weather from wttr.in (curl, JSON), for the desktop weather widget.
// Only polls while `wanted` (widget visible): every 30 min, and right away
// when the city changes. Empty city = wttr.in guesses it from the IP.
Singleton {
    id: root

    property bool wanted: false
    property string city: ""

    property bool loaded: false
    property bool failed: false
    property real tempC: NaN
    property real feelsC: NaN
    property real maxC: NaN
    property real minC: NaN
    property int humidity: 0
    property string desc: ""
    property string place: ""
    property int code: 113
    property bool night: false

    // Material Symbols name for the current condition (IconMap has fallbacks)
    readonly property string icon: {
        const c = code;
        if (c === 113) return night ? "clear_night" : "sunny";
        if (c === 116) return night ? "partly_cloudy_night" : "partly_cloudy_day";
        if (c === 119 || c === 122) return "cloud";
        if ([143, 248, 260].includes(c)) return "foggy";
        if ([200, 386, 389, 392, 395].includes(c)) return "thunderstorm";
        if ([179, 182, 185, 227, 230, 317, 320, 323, 326, 329, 332, 335, 338, 350,
             362, 365, 368, 371, 374, 377].includes(c)) return "weather_snowy";
        return "rainy";
    }

    function temp(c, fahrenheit) {
        if (isNaN(c)) return "–";
        return Math.round(fahrenheit ? c * 9 / 5 + 32 : c) + "°";
    }

    function refresh() { if (wanted) fetch.running = true; }
    onCityChanged: refresh()
    onWantedChanged: refresh()

    Timer {
        interval: 30 * 60 * 1000
        repeat: true
        running: root.wanted
        onTriggered: root.refresh()
    }

    Process {
        id: fetch
        command: ["curl", "-sf", "--max-time", "12",
                  "https://wttr.in/" + encodeURIComponent(root.city.trim()) + "?format=j1"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const d = JSON.parse(text);
                    const cur = d.current_condition[0];
                    const day = d.weather?.[0];
                    root.tempC = Number(cur.temp_C);
                    root.feelsC = Number(cur.FeelsLikeC);
                    root.humidity = Number(cur.humidity);
                    root.code = Number(cur.weatherCode);
                    root.desc = cur.weatherDesc?.[0]?.value?.trim() ?? "";
                    root.maxC = Number(day?.maxtempC ?? NaN);
                    root.minC = Number(day?.mintempC ?? NaN);
                    root.place = root.city.trim() !== "" ? root.city.trim()
                               : (d.nearest_area?.[0]?.areaName?.[0]?.value ?? "");
                    // night between today's sunset and sunrise (local time, "07:12 AM")
                    const astro = day?.astronomy?.[0];
                    if (astro) {
                        const mins = s => {
                            const m = /(\d+):(\d+)\s*(AM|PM)/.exec(s ?? "");
                            return m ? (Number(m[1]) % 12 + (m[3] === "PM" ? 12 : 0)) * 60 + Number(m[2]) : -1;
                        };
                        const now = new Date();
                        const t = now.getHours() * 60 + now.getMinutes();
                        const rise = mins(astro.sunrise), set = mins(astro.sunset);
                        root.night = rise >= 0 && set >= 0 && (t < rise || t > set);
                    }
                    root.failed = false;
                    root.loaded = true;
                } catch (e) {
                    root.failed = true;
                }
            }
        }
        onExited: code => { if (code !== 0) root.failed = true; }
    }
}
