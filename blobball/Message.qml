pragma Singleton
import QtQuick

// Transienter, nicht persistierter Nachrichten-Zustand fuer die
// IPC-Anzeige ("qs ... ipc call notify show <text>", siehe shell.qml).
// Bewusst KEIN org.freedesktop.Notifications-Server (Quickshell.Services.
// Notifications): dieser D-Bus-Name ist auf dem System bereits von einer
// anderen laufenden Quickshell-Instanz belegt (siehe README) -- ein
// zweiter Bewerber wuerde den Namen entweder nicht bekommen oder dem
// bestehenden System-Benachrichtigungsweg in die Quere kommen. Stattdessen
// ruft eine externe Stelle (Skript, Keybind, oder ein Hook in der
// bestehenden Notifications-Bar) gezielt die IPC-Funktion auf, wenn der
// Blob etwas anzeigen soll.
QtObject {
    id: root

    property string text: ""
    property bool visible: false

    // Verlauf aller seit Start dieser Instanz per IPC angezeigten Nachrichten
    // ("Postkasten" fuer den Blob in der Ecke, siehe BlobWindow.qml) + Zaehler
    // der noch nicht angesehenen. Bewusst nur In-Memory, nicht auf Platte
    // persistiert -- gleiche Begruendung wie oben (kein echter Notification-
    // Server, alles transient).
    property var history: []
    property int unreadCount: 0
    readonly property int _maxHistory: 100

    function show(t) {
        root.text = t;
        root.visible = true;
        hideTimer.restart();

        const h = root.history.concat([{ text: t, time: Date.now() }]);
        while (h.length > root._maxHistory) h.shift();
        root.history = h;
        root.unreadCount += 1;
    }

    function clear() {
        root.visible = false;
        hideTimer.stop();
    }

    function clearHistory() {
        root.history = [];
        root.unreadCount = 0;
    }

    function markAllRead() {
        root.unreadCount = 0;
    }

    onTextChanged: hideTimer.interval = Math.max(4000, Math.min(12000, 4000 + root.text.length * 60))

    property Timer hideTimer: Timer {
        interval: 4000
        onTriggered: root.visible = false
    }
}
