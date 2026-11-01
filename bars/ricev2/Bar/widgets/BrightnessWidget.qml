import QtQuick
import "../../"

// Bar prompt section 4, "brightness" row: %, icon by quartile (<25 F00DE,
// <50 F00DF, <75 F00DD, else F00E0). Hidden with no backlight device found
// (SystemService.brightnessAvailable, via brightnessctl). Scroll wheel
// ±5% is real functionality (independent of any dropdown), so it's wired
// now; click (opening the brightness dropdown) is Stage 3.
Row {
    id: root
    spacing: 4

    readonly property bool available: SystemService.brightnessAvailable
    readonly property int _percent: Math.round(SystemService.brightness * 100)

    readonly property string _iconGlyph: {
        if (root._percent < 25)
            return "\u{F00DE}";
        if (root._percent < 50)
            return "\u{F00DF}";
        if (root._percent < 75)
            return "\u{F00DD}";
        return "\u{F00E0}";
    }

    Text {
        font.family: Style.iconFont
        font.pixelSize: 14
        color: Colors.primary
        text: root._iconGlyph
    }
    Text {
        font.family: Style.textFont
        font.pixelSize: 12
        font.weight: Font.Medium
        color: Colors.tertiary
        text: root._percent + "%"
    }

    WheelHandler {
        target: null
        onWheel: event => {
            const delta = event.angleDelta.y > 0 ? 0.05 : -0.05;
            SystemService.setBrightness(SystemService.brightness + delta);
        }
    }
}
