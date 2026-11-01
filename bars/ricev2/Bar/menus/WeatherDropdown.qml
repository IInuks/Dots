import QtQuick
import "../../"

// Weather dropdown content (menus prompt 1.5). Config only names a single
// city (Config.weatherCity, "Wien" -- see README "Bevorzugter Player"-style
// single-value config), so the city-switch arrows are always in the
// prompt's explicit "bei nur einer Stadt" dimmed/disabled state rather than
// paging through a city list that doesn't exist.
Column {
    id: root
    width: Style.dropdownMinWidth - 24
    spacing: 10

    readonly property var forecast: WeatherService.dailyForecast

    // -- Header: city arrows (disabled, single city) + name -------------
    Item {
        width: parent.width
        height: 18

        Text {
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            font.family: Style.iconFont
            font.pixelSize: 14
            color: Qt.rgba(Colors.primary.r, Colors.primary.g, Colors.primary.b, 0.25)
            text: "\u{F004D}"
        }
        Text {
            anchors.centerIn: parent
            font.family: Style.textFont
            font.pixelSize: 13
            color: Colors.primary
            text: Config.weatherCity.toUpperCase()
        }
        Text {
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            font.family: Style.iconFont
            font.pixelSize: 14
            color: Qt.rgba(Colors.primary.r, Colors.primary.g, Colors.primary.b, 0.25)
            text: "\u{F0054}"
        }
    }

    // -- "Jetzt" block ----------------------------------------------------
    Row {
        width: parent.width
        spacing: 12

        Text {
            font.family: Style.iconFont
            font.pixelSize: 40
            color: Colors.primary
            text: WeatherService.iconGlyph
        }
        Column {
            anchors.verticalCenter: parent.verticalCenter
            spacing: 2
            Text {
                font.family: Style.textFont
                font.pixelSize: 30
                color: Colors.backgroundText
                text: (isNaN(WeatherService.temperature) ? "--" : Math.round(WeatherService.temperature)) + "°"
            }
            Text {
                font.family: Style.textFont
                font.pixelSize: 12
                opacity: 0.75
                color: Colors.backgroundText
                text: WeatherService.description
            }
        }
    }

    // -- Forecast cards ---------------------------------------------------
    Row {
        width: parent.width
        spacing: 4

        Repeater {
            model: root.forecast

            Rectangle {
                id: card
                required property var modelData
                required property int index
                readonly property bool isToday: card.index === 0
                width: (root.width - 4 * (root.forecast.length - 1)) / Math.max(1, root.forecast.length)
                height: 124
                radius: 8
                color: card.isToday ? Qt.rgba(Colors.primary.r, Colors.primary.g, Colors.primary.b, 0.12) : "transparent"
                border.width: card.isToday ? 1 : 0
                border.color: Qt.rgba(Colors.primary.r, Colors.primary.g, Colors.primary.b, 0.35)

                Column {
                    anchors.fill: parent
                    anchors.margins: 4
                    spacing: 1

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        font.family: Style.textFont
                        font.pixelSize: 10
                        font.weight: Font.Medium
                        color: Colors.backgroundText
                        text: card.modelData.dayLabel
                    }
                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        font.family: Style.iconFont
                        font.pixelSize: 20
                        color: Colors.primary
                        text: card.modelData.icon
                    }
                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        font.family: Style.textFont
                        font.pixelSize: 11
                        font.weight: Font.DemiBold
                        color: Colors.backgroundText
                        text: card.modelData.tempMax + "°"
                    }
                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        font.family: Style.textFont
                        font.pixelSize: 10
                        opacity: 0.7
                        color: Colors.tertiary
                        text: card.modelData.tempMin + "°"
                    }
                    Row {
                        anchors.horizontalCenter: parent.horizontalCenter
                        spacing: 2
                        visible: card.modelData.rain >= 0.1
                        Text { font.family: Style.iconFont; font.pixelSize: 11; opacity: 0.85; color: Colors.tertiary; text: "\u{F058E}" }
                        Text { font.family: Style.textFont; font.pixelSize: 11; opacity: 0.85; color: Colors.tertiary; text: card.modelData.rain.toFixed(1) }
                    }
                    Row {
                        anchors.horizontalCenter: parent.horizontalCenter
                        spacing: 2
                        Text { font.family: Style.iconFont; font.pixelSize: 11; opacity: 0.85; color: Colors.tertiary; text: "\u{F059D}" }
                        Text { font.family: Style.textFont; font.pixelSize: 11; opacity: 0.85; color: Colors.tertiary; text: String(card.modelData.wind) }
                    }
                }
            }
        }
    }
}
