import QtQuick
import "../../"

// Bar prompt section 4, "weather" row: temperature, icon from
// WeatherService's WMO-code mapping. Hidden until the first successful
// Open-Meteo fetch lands (no "N/A" flash on startup). Click opens the
// weather dropdown (menus prompt 1.5, Stage 3) -- the click catcher is a
// sibling of the Row, not a child of it: a Row child can't use
// `anchors.fill` (Row positions children itself and warns/no-ops on that),
// so the click area lives one level up.
Item {
    id: root

    readonly property bool available: WeatherService.ready

    implicitWidth: content.implicitWidth
    implicitHeight: content.implicitHeight

    Row {
        id: content
        anchors.verticalCenter: parent.verticalCenter
        spacing: 4

        Text {
            font.family: Style.iconFont
            font.pixelSize: 14
            color: Colors.primary
            text: WeatherService.iconGlyph
        }
        Text {
            font.family: Style.textFont
            font.pixelSize: 12
            font.weight: Font.Medium
            color: Colors.tertiary
            text: Math.round(WeatherService.temperature) + "°"
        }
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: DropdownState.toggle("weather")
    }
}
