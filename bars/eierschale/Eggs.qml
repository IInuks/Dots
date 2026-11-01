pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Das Überraschungsei: Figurenkatalog, deine Sammlung, der Zufall, und der
// Zustand der Sanduhr (die läuft weiter, auch wenn das Menü zu ist, und
// lässt das Ei in der Leiste klingeln).
Singleton {
    id: root

    // glyph = Name in Icons.qml. rarity: 1 = normal, 2 = selten, 3 = sehr selten
    readonly property var toys: [
        { id: "wuerfel", name: "Würfel", rarity: 1, glyph: "dice", text: "Klick drauf und würfle." },
        { id: "muenze",  name: "Glücksmünze", rarity: 1, glyph: "coin", text: "Kopf oder Zahl? Wirf sie." },
        { id: "keks",    name: "Glückskeks", rarity: 1, glyph: "cookie", text: "Brich ihn auf." },
        { id: "orakel",  name: "Orakelkugel", rarity: 1, glyph: "ball", text: "Stell eine Ja/Nein-Frage, dann schüttel." },
        { id: "blasen",  name: "Luftpolsterfolie", rarity: 1, glyph: "bubbles", text: "Plopp. Plopp. Plopp." },
        { id: "farbe",   name: "Farbe des Tages", rarity: 2, glyph: "palette", text: "Jeden Tag eine andere." },
        { id: "mond",    name: "Mondphase", rarity: 2, glyph: "moon", text: "So sieht der Mond heute aus." },
        { id: "sanduhr", name: "Sanduhr", rarity: 2, glyph: "sand", text: "Ein Kurzzeitwecker. Das Ei klingelt." },
        { id: "jahr",    name: "Jahresuhr", rarity: 2, glyph: "calendar", text: "Wie viel vom Jahr schon rum ist." },
        { id: "goldei",  name: "Goldenes Ei", rarity: 3, glyph: "eggEaster", text: "Das seltenste Stück. Glückwunsch!" }
    ]
    readonly property var weights: ({ 1: 13, 2: 8, 3: 3 })
    readonly property var rarityNames: ({ 1: "normal", 2: "selten", 3: "sehr selten" })

    function toy(id) { return toys.find(t => t.id === id) || null; }
    function indexOf(id) { return toys.findIndex(t => t.id === id); }

    // ---------------------------------------------------------- Sammlung
    property var found: ({})     // id -> Anzahl
    property int opened: 0
    readonly property int uniqueFound: toys.filter(t => (found[t.id] || 0) > 0).length

    FileView {
        id: store
        path: Quickshell.statePath("eierschale-eier.json")
        printErrors: false
        onLoaded: {
            try {
                const d = JSON.parse(text());
                root.found = d.found || {};
                root.opened = d.opened || 0;
            } catch (e) {}
        }
    }
    function _save() { store.setText(JSON.stringify({ found: root.found, opened: root.opened })); }

    // Zieht eine Figur. Rückgabe: { toy, isNew }
    function draw() {
        let sum = 0;
        for (const t of toys) sum += weights[t.rarity];
        let r = Math.random() * sum, pick = toys[0];
        for (const t of toys) { r -= weights[t.rarity]; if (r <= 0) { pick = t; break; } }
        const f = Object.assign({}, root.found);   // neues Objekt, sonst merkt QML nichts
        const isNew = !(f[pick.id] > 0);
        f[pick.id] = (f[pick.id] || 0) + 1;
        root.found = f;
        root.opened += 1;
        _save();
        return { toy: pick, isNew: isNew };
    }

    // ---------------------------------------------------------- Sanduhr
    property real timerEnd: 0        // epoch ms, 0 = aus
    property real timerTotal: 0
    property real now: Date.now()
    property bool ringing: false
    readonly property bool timerRunning: timerEnd > 0
    readonly property real timerLeft: timerRunning ? Math.max(0, timerEnd - now) : 0
    readonly property real timerProgress: timerRunning && timerTotal > 0 ? 1 - timerLeft / timerTotal : 0

    function startTimer(minutes) {
        timerTotal = minutes * 60000;
        timerEnd = Date.now() + timerTotal;
        now = Date.now();
        ringing = false;
    }
    function stopTimer() { timerEnd = 0; ringing = false; }

    Timer {
        interval: 1000
        repeat: true
        running: root.timerRunning
        onTriggered: {
            root.now = Date.now();
            if (root.now >= root.timerEnd) {
                root.timerEnd = 0;
                root.ringing = true;
                Quickshell.execDetached(["notify-send", "-a", "eierschale", "Sanduhr", "Die Zeit ist um."]);
            }
        }
    }

    // ---------------------------------------------------------- Texte
    readonly property var fortunes: [
        "Wer nichts wagt, der nichts gewinnt, aber schläft besser.",
        "Heute klappt etwas, das gestern noch gehakt hat.",
        "Ein kleiner Umweg zeigt dir etwas Schönes.",
        "Trink ein Glas Wasser. Der Keks meint es ernst.",
        "Die beste Zeit für einen Commit war vor einer Stunde. Die zweitbeste ist jetzt.",
        "Jemand denkt gerade gut über dich nach.",
        "Du wirst einen Bug finden, der gar keiner war.",
        "Geduld. Auch Eier brauchen ihre Zeit.",
        "Räum eine Sache auf, und der Tag wird leichter.",
        "Das Glück liegt in der Schale, nicht im Dotter.",
        "Heute ist ein guter Tag für neue Dotfiles.",
        "Mach eine Pause, bevor die Pause dich macht."
    ]
    readonly property var oracle: [
        "Ja, auf jeden Fall.", "Sieht gut aus.", "Frag später nochmal.", "Eher nicht.",
        "Ohne Zweifel.", "Da bin ich mir nicht sicher.", "Nein.", "Die Zeichen stehen auf Ja.",
        "Konzentrier dich und frag erneut.", "Lieber nicht verraten."
    ]
}
