import QtQuick
import "../"
import "../Bar"

Row {
    id: root
    spacing: 10
    height: 36

    Icon {
        anchors.verticalCenter: parent.verticalCenter
        glyph: WeatherService.iconGlyph
        fallback: "☁"
        font.pixelSize: 22
        visible: WeatherService.locationConfigured
    }

    Column {
        anchors.verticalCenter: parent.verticalCenter
        spacing: 1

        Text {
            visible: !WeatherService.locationConfigured
            text: "Ort in den Einstellungen festlegen"
            color: Theme.outline
            font.pixelSize: 11
            font.family: Theme.uiFontFamily
        }
        Text {
            visible: WeatherService.locationConfigured && WeatherService.error.length > 0
            text: WeatherService.error
            color: Theme.critical
            font.pixelSize: 11
            font.family: Theme.uiFontFamily
        }
        Text {
            visible: WeatherService.locationConfigured && WeatherService.ready
            text: (isNaN(WeatherService.temperature) ? "…" : Math.round(WeatherService.temperature) + "°C") + " · " + WeatherService.description
            color: Theme.surfaceInk
            font.pixelSize: 12
            font.family: Theme.uiFontFamily
        }
        Text {
            visible: WeatherService.locationConfigured && WeatherService.ready
            text: WeatherService.resolvedName
            color: Theme.outline
            font.pixelSize: 10
            font.family: Theme.uiFontFamily
        }
    }
}
