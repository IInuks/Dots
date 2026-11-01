import QtQuick
import Quickshell
import "../.."

// Datum + Uhrzeit, sekuendlich aktualisiert. Wird sowohl im kollabierten
// Notch (grosse Schrift, nur Uhrzeit) als ueber Settings.clockFormatCollapsed
// als auch in der aufgeklappten Kopfzeile (Standardformat) verwendet --
// format/pointSize/color ueberschreibbar statt zweier Kopien.
Text {
    id: root

    property string format: Settings.clockFormat
    property int pointSize: Colors.fontSize

    SystemClock {
        id: clock
        precision: SystemClock.Seconds
    }

    // Feste en_US-Locale, damit Monatsname/AM-PM unabhaengig von der
    // Systemsprache (hier: Oesterreich/de_AT) immer englisch bleiben.
    text: clock.date.toLocaleString(Qt.locale("en_US"), root.format)
    font.family: Colors.fontFamily
    font.pointSize: root.pointSize
    font.letterSpacing: Colors.letterSpacing
    color: Colors.text
}
