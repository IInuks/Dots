pragma Singleton

import QtQuick
import Quickshell

// Icon names follow Material Symbols. If that font is not installed, the same names are
// mapped to the Material Design glyphs inside the JetBrainsMono Nerd Font.
Singleton {
    readonly property var nerd: ({
        "apps": 0xf003b,
        "speed": 0xf0ee0,
        "memory": 0xf035b,
        "device_thermostat": 0xf050f,
        "volume_up": 0xf057e,
        "volume_down": 0xf0580,
        "volume_mute": 0xf057f,
        "volume_off": 0xf0581,
        "brightness_6": 0xf00df,
        "light_mode": 0xf05a8,
        "battery_full": 0xf0079,
        "battery_charging_full": 0xf0084,
        "battery_alert": 0xf0083,
        "notifications": 0xf009c,
        "notifications_off": 0xf0a91,
        "power_settings_new": 0xf0906,
        "home": 0xf06a1,
        "music_note": 0xf0387,
        "graphic_eq": 0xf04c3,
        "desktop_windows": 0xf0379,
        "computer": 0xf0aab,
        "settings": 0xf08bb,
        "close": 0xf0156,
        "wifi": 0xf0928,
        "wifi_off": 0xf05aa,
        "lan": 0xf0200,
        "bluetooth": 0xf00af,
        "bluetooth_disabled": 0xf00b2,
        "bluetooth_connected": 0xf00b1,
        "calendar_month": 0xf0e18,
        "dark_mode": 0xf0594,
        "do_not_disturb_on": 0xf0377,
        "videocam": 0xf0bdc,
        "chevron_left": 0xf0141,
        "chevron_right": 0xf0142,
        "play_arrow": 0xf040a,
        "pause": 0xf03e4,
        "skip_next": 0xf04ad,
        "skip_previous": 0xf04ae,
        "album": 0xf0025,
        "restart_alt": 0xf0709,
        "logout": 0xf0343,
        "lock": 0xf0341,
        "bedtime": 0xf04b2,
        "person": 0xf0b55,
        "hard_drive": 0xf02ca,
        "mic": 0xf036c,
        "mic_off": 0xf036d,
        "headphones": 0xf02cb,
        "check": 0xf012c,
        "delete": 0xf09e7,
        "search": 0xf0349,
        "refresh": 0xf0450,
        "chat": 0xf0365,
        "terminal": 0xf0614,
        "dns": 0xf048b,
        "key": 0xf0306,
        "tune": 0xf1542,
        "more_horiz": 0xf01d8,
        // weather widget (wttr.in codes → names in services/Weather.qml)
        "sunny": 0xf0599,
        "clear_night": 0xf0594,
        "partly_cloudy_day": 0xf0595,
        "partly_cloudy_night": 0xf0f31,
        "cloud": 0xf0590,
        "foggy": 0xf0591,
        "rainy": 0xf0597,
        "weather_snowy": 0xf0598,
        "thunderstorm": 0xf067e,
        "humidity_percentage": 0xf058e,
        "location_on": 0xf034e,
        "waving_hand": 0xf1821
    })

    function glyph(name) {
        const cp = nerd[name];
        return cp === undefined ? "?" : String.fromCodePoint(cp);
    }
}
