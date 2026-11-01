import QtQuick
import ".."

// Rotating Font Awesome spinner glyph.
Icon {
    id: spinner
    property bool running: true
    text: ""
    color: Theme.accent
    RotationAnimation on rotation {
        running: spinner.running
        from: 0; to: 360
        duration: 900
        loops: Animation.Infinite
    }
}
