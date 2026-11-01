pragma Singleton
import QtQuick
import Quickshell

Singleton {
    // Geometrie der Leiste: Schleifen ragen in bowRoom hinein, die Kartons
    // sind boxHeight hoch. Darunter liegt unsichtbarer Platz, in den das
    // Konfetti fallen darf (Klicks gehen dort durch, siehe Bar.qml mask).
    readonly property int bowRoom: 13
    readonly property int boxHeight: 31
    readonly property int barHeight: 47
    readonly property int confettiRoom: 120
    readonly property int edgeMargin: 14
    readonly property int giftSpacing: 10

    // "Bescherung": beim Start sind alle Geschenke verpackt und packen sich
    // nacheinander selbst aus. false = Leiste startet ausgepackt.
    readonly property bool bescherungOnStart: true
    readonly property int bescherungDelay: 700
    readonly property int bescherungStagger: 170
    readonly property int confettiPieces: 18

    readonly property int tagCount: 6
    readonly property int titleMaxWidth: 380

    readonly property int statsInterval: 2500
    readonly property real volumeStep: 0.05

    readonly property var powerActions: [
        { label: "Abmelden", icon: "\uf08b", cmd: ["mmsg", "dispatch", "quit"] },
        { label: "Bereitschaft", icon: "\uf186", cmd: ["loginctl", "suspend"] },
        { label: "Neustart", icon: "\uf021", cmd: ["loginctl", "reboot"] },
        { label: "Ausschalten", icon: "\uf011", cmd: ["loginctl", "poweroff"] }
    ]
}
