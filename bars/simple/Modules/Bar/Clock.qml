import QtQuick
import Quickshell
import "../.."

// Mittlerer Bar-Bereich: Datum + Uhrzeit, sekuendlich aktualisiert.
Text {
    id: root

    SystemClock {
        id: clock
        precision: SystemClock.Seconds
    }

    // Feste en_US-Locale, damit Monatsname und AM/PM unabhaengig von der
    // Systemsprache (hier: Oesterreich/de_AT) immer englisch bleiben.
    text: clock.date.toLocaleString(Qt.locale("en_US"), Settings.clockFormat)
    font.family: Colors.fontFamily
    font.pointSize: Colors.fontSize
    font.letterSpacing: Colors.letterSpacing
    color: Colors.text
}
