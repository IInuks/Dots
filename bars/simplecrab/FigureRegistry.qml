pragma Singleton
import QtQuick

// Zentrale Liste aller im Menue waehlbaren Figuren. Die Auswahl im
// Spinnen-Menue (Modules/Spider/SpiderMenu.qml) baut sich automatisch aus
// dieser Liste.
//
// Neue Figur hinzufuegen, ehrlich in drei Schritten (nicht nur einer, siehe
// README fuer die Begruendung):
//   1. Modules/Spider/Figures/<Name>/<Name>.qml anlegen (Item mit den
//      Properties size/heading/moving, siehe Figures/Spider/Spider.qml).
//   2. In Modules/Spider/Figures/FigureView.qml importieren + in der
//      Komponenten-Map eintragen.
//   3. Hier eine Zeile mit id/Anzeigename ergaenzen.
QtObject {
    readonly property var figures: [
        {
            id: "spider",
            name: "Spinne"
        },
        {
            id: "crab",
            name: "Krabbe"
        }
    ]
}
