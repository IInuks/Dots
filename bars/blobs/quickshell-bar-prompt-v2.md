# Claude Code Prompt — Quickshell Three-Dot Bar (v2)

> Kopiere alles ab "## Auftrag" in Claude Code.

---

## Auftrag

Baue mir eine Quickshell-Leiste (QML) für MangoWM. Die Leiste besteht aus genau drei
schwebenden Elementen, horizontal zentriert am oberen Bildschirmrand.

Das zentrale Gestaltungsprinzip: **es gibt keine Popups.** Die drei Elemente sind die
Menüs — sie verformen sich beim Anklicken selbst von einer Kugel bzw. Pille zu einer
Menüfläche und wieder zurück. Zu keinem Zeitpunkt erscheint ein separates Fenster, das
über der Leiste liegt.

### Vorgehen (bitte einhalten)

1. Prüfe zuerst die Umgebung, bevor du Code schreibst:
   - `quickshell --version`, verfügbare QML-Module unter `Quickshell.*`
   - `mmsg -g -t` und `mmsg -w -t` — Ausgabeformat der Tags ansehen
   - Sensoren: `ls /sys/class/hwmon/*/name` und die zugehörigen `temp*_input`
   - ob `matugen`, `swww`/`wpaperd`, PipeWire vorhanden sind
2. Zeig mir einen kurzen Plan (Dateistruktur + genutzte APIs), warte auf mein OK.
3. Dann implementieren, in kleinen Schritten, jeweils lauffähig.

Wenn eine API anders heißt als hier beschrieben, richte dich nach der tatsächlich
installierten Quickshell-Version — rate nicht, schau in Doku bzw. Modulen nach.

---

## 1. Stack & Umgebung

- **Compositor:** MangoWM (dwl-basiert, wlroots). Kein Hyprland-IPC!
  Statusabfrage ausschließlich über `mmsg`.
- **Shell:** Quickshell, QML/QtQuick, Layer-Shell über `Quickshell.Wayland`.
- **Config-Pfad:** `~/.config/quickshell/bar/`
- **User:** `PRIVATE_VALUE`, Wallpaper-Ordner: `~/Pictures/Wallpaper`

```
~/.config/quickshell/bar/
├── shell.qml
├── Bar.qml                # Layout-Logik: Positionen, Schiebeverhalten
├── components/
│   ├── MorphBlob.qml      # Basiskomponente: verformbare Fläche
│   ├── WorkspaceBlob.qml
│   ├── ClockBlob.qml
│   ├── TempBlob.qml
│   ├── TempRing.qml
│   └── ClickCatcher.qml
├── content/
│   ├── WorkspaceContent.qml
│   ├── CalendarContent.qml
│   ├── LauncherContent.qml
│   └── AudioContent.qml
├── services/
│   ├── Mango.qml          # mmsg watch → aktiver Tag
│   ├── Cpu.qml
│   ├── Audio.qml
│   ├── Wallpaper.qml
│   ├── BarState.qml       # zentraler State (welches Element ist offen)
│   └── Settings.qml       # persistente Einstellungen (JSON)
└── theme/
    └── Theme.qml
```

---

## 2. Geometrie und Schiebeverhalten

- `PanelWindow` (Layer-Shell), `anchors.top: true`, `exclusiveZone: 0` — die Leiste
  schwebt über den Fenstern, Fenster weichen ihr nicht aus.
- Fensterhintergrund vollständig transparent, nur die Elemente sind sichtbar.
- Das Fenster muss hoch genug sein, dass die größte Menüfläche hineinpasst; Bereiche
  ohne sichtbaren Inhalt dürfen **keine** Mausklicks abfangen (`mask` bzw.
  `InputMask` passend zur tatsächlich sichtbaren Fläche setzen, bei jeder
  Größenänderung mitführen).
- Abstand nach oben 8 px, Abstand zwischen den Elementen konstant **12 px**.
- Ruhezustand: linke Kugel 46 × 46, mittlere Pille 118 × 46, rechte Kugel 46 × 46.
  Beide Kugeln exakt gleich groß.

### Positionierung — wichtig

Die drei Elemente überlappen einander **niemals**. Die Position der Kugeln wird aus
der aktuellen Breite des mittleren Blobs berechnet:

```
linke Kugel:  rechte Kante = Bildschirmmitte − mittlereBreite/2 − 12
rechte Kugel: linke Kante  = Bildschirmmitte + mittlereBreite/2 + 12
```

Wächst der mittlere Blob (Kalender, Launcher), **schiebt** er die beiden Kugeln
symmetrisch nach außen. Er legt sich nicht über sie und verdeckt sie nicht. Das
Schieben nutzt dieselbe Dauer und dieselbe Easing-Kurve wie die Breitenänderung des
Blobs, damit es wie eine einzige zusammenhängende Bewegung wirkt.

Die linke Kugel wächst nach links und unten, die rechte nach rechts und unten — beide
also vom mittleren Blob **weg**. Dadurch ist kein Schieben nötig, wenn eine Kugel
aufgeht; der mittlere Blob bleibt dann stehen.

---

## 3. Morph-Verhalten (Kern der Optik)

Gemeinsame Basiskomponente `MorphBlob.qml`, die alle drei Elemente nutzen. Beim Öffnen
verändert **dasselbe Rechteck** seine Eigenschaften:

- `implicitWidth` und `implicitHeight` wachsen auf die Zielgröße des Inhalts
- `radius` geht von `height / 2` (perfekte Kugel/Pille) auf 16 px
- Dauer ~380 ms, Easing `Easing.OutCubic` oder leichte Overshoot-Kurve;
  `radius` minimal schneller (~340 ms), damit die Form früh "zur Fläche wird"
- `clip: true` — Inhalt wird während des Wachsens von der Form beschnitten
- Schließen ist dieselbe Animation rückwärts, ~300 ms

### Verankerung beim Verformen

Das ursprüngliche Element-Symbol bleibt beim Wachsen **an Ort und Stelle** und wird
zur Kopfzeile der Menüfläche:

| Element | Ankerpunkt | Wachstumsrichtung | Symbol landet |
|---|---|---|---|
| links | oben rechts | nach links und unten | oben rechts |
| Mitte | oben mittig | nach beiden Seiten und unten | oben mittig |
| rechts | oben links | nach rechts und unten | oben links |

Die Kopfzeile ist 46 px hoch — exakt die Ruhehöhe. Dadurch wandert das Symbol (Zahl,
Uhrzeit, Temperaturring) beim Öffnen **kein einziges Pixel**. Nur die Fläche darum
wächst. Prüfe das explizit: Zahl und Ring dürfen beim Öffnen nicht springen.

### Inhalt

Der Menüinhalt blendet **verzögert** ein: `opacity` 0 → 1 über 220 ms mit ~160 ms
Verzögerung, also erst wenn die Form fast ihre Endgröße hat. Beim Schließen
verschwindet er sofort (kein Delay), bevor die Form schrumpft. Zusatzbeschriftungen in
der Kopfzeile (z. B. "Workspace", "CPU-Temperatur") blenden mit derselben Verzögerung ein.

---

## 4. Linke Kugel — Tag / Workspace

**Ruhe:** Nummer des aktiven Tags, zentriert.

**Datenquelle:** `mmsg -w -t` als Dauerprozess (`Quickshell.Io.Process`, `SplitParser`
auf stdout), JSON parsen, aktiven Tag ableiten. Beim Start einmal `mmsg -g -t` für den
Initialwert. Prozess bei Absturz automatisch neu starten. Tag-Wechsel animiert die
Zahl weich (Fade + 2 px Slide in Wechselrichtung).

**Geöffnet** (ca. 268 × 256 px):

- **Transparenz-Slider** (0–100 %), steuert live die Deckkraft aller Leisten-Elemente,
  Wert persistent gespeichert.
- **Wallpaper-Grid:** Thumbnails aller Bilder aus `~/Pictures/Wallpaper`
  (jpg/jpeg/png/webp). Klick auf ein Bild:
  1. Wallpaper setzen (`swww img <pfad>` bevorzugt, sonst `wpaperd`; ist keines
     installiert, frag mich)
  2. `matugen image <pfad>` ausführen
  3. Theme neu laden (Abschnitt 8)
  Aktives Wallpaper mit Rahmen markiert, Thumbnails gecached — das Grid darf beim
  Öffnen nicht ruckeln.

---

## 5. Mittlerer Blob — Uhr, Kalender, Launcher

Drei Zustände derselben Fläche:

### a) Ruhe (118 × 46)
Digitale Uhrzeit, 24 h, `HH:mm`. Minütlich aktualisieren, auf die volle Minute
synchronisiert. Ziffern mit fester Breite, damit nichts springt.

### b) Kalender — Klick auf den Blob (ca. 282 × 104)
Blob wird etwas breiter und etwas höher. Die Uhrzeit bleibt oben in der Kopfzeile,
darunter erscheinen die sieben Wochentage (Mo–So) in einer Reihe, der aktuelle Tag
hervorgehoben (gefüllter Hintergrund in der Akzentfarbe). Die Kugeln rücken um die
Breitendifferenz nach außen.

### c) App-Launcher — `Super + Space` (ca. 420 × 236)
Blob verlängert sich deutlich, die Uhrzeit wird durch Lupensymbol und Textfeld
ersetzt (Crossfade, kein hartes Umschalten). Darunter die Trefferliste, max. 6 sichtbar.

- Quelle: `Quickshell.DesktopEntries` — Name, Icon, Exec
- Fuzzy-Matching auf Name und generischen Namen, Sortierung nach Score
- `Enter` startet, `↑`/`↓` navigieren, Maus-Hover markiert ebenfalls
- Keyboard-Fokus nur solange der Launcher offen ist
  (`WlrKeyboardFocus.Exclusive`), danach **sofort** freigeben — die Leiste darf im
  Ruhezustand niemals Fokus stehlen
- Das Keybinding lege ich in der Mango-Config an; richte dafür einen `IpcHandler` ein
  (`qs ipc call launcher toggle`) und gib mir die passende Zeile für
  `~/.config/mango/config.conf` aus

Kalender und Launcher schließen sich gegenseitig aus. Wechselt man direkt zwischen
beiden, morpht die Fläche ohne Zwischenschritt in die neue Größe.

---

## 6. Rechte Kugel — CPU-Temperatur, Audio, Systemmonitor

**Ruhe:** Temperatur als Zahl mit Gradzeichen (z. B. `55°`) in der Mitte, außen herum
ein Fortschrittsring.

### Der Ring — genaue Vorgaben

- **Startpunkt: 8-Uhr-Position. Endpunkt: 4-Uhr-Position.** Der Bogen läuft im
  Uhrzeigersinn über oben, also über 240 Grad; unten bleibt eine Lücke von 120 Grad.
- Zwei Bögen übereinander: die volle Bahn in der Randfarbe des Themes, darüber der
  gefüllte Teil in der Statusfarbe. Beide mit runden Enden.
- Der Ring liegt **innerhalb** der 46 × 46 px, Strichstärke ~2.5 px, nah am Rand.
  Die Kugel wird durch den Ring **nicht größer** — weder im Ruhezustand noch bei
  hoher Temperatur.
- Skala: 30 °C = leer, 95 °C = voller Bogen, linear dazwischen, Werte darüber
  begrenzen statt überlaufen lassen.
- Farbe: grün bis 65 °C, amber bis 80 °C, darüber rot. Übergang animiert
  (`ColorAnimation`), kein Umspringen.
- Der Füllstand animiert ebenfalls (`Behavior on progress`, ~400 ms).
- Umsetzung mit `Shape`/`ShapePath` und `PathAngleArc` (`startAngle` und `sweepAngle`
  direkt setzen) — das ist sauberer als ein gedrehtes Canvas.
- Quelle: `/sys/class/hwmon/*/temp*_input` (k10temp `Tctl` bzw. coretemp
  `Package id 0`). Sensor beim Start einmal auflösen, dann alle 2 s per `FileView`
  lesen — kein Shell-Prozess im Polling-Loop.

### Geöffnet (ca. 268 × 232)

Ring und Zahl bleiben oben links stehen, rechts daneben die Beschriftung. Darunter
zwei Tabs:

**Tab 1 — Audio:** Master-Lautstärke (Slider, Prozentwert, Mute-Toggle), darunter pro
Anwendung ein eigener Slider mit App-Name und Icon. Quelle:
`Quickshell.Services.Pipewire` (Sinks und Stream-Nodes), bidirektional — Änderungen
von außen (z. B. per Keybind) erscheinen sofort in der UI. Liste aktualisiert sich
live, wenn Streams kommen oder gehen.

**Tab 2 — Systemmonitor:** kompakte Zeilen mit Label und Wert: CPU-Auslastung, RAM
(genutzt / gesamt), GPU-Temperatur (nur wenn Sensor vorhanden), Netzwerk-Durchsatz,
Uptime. Quellen: `/proc/stat`, `/proc/meminfo`, `/proc/net/dev`, `/proc/uptime`.
Aktualisierung alle 2 s und **nur solange der Tab sichtbar ist** — keine Timer im
Leerlauf.

Tab-Wechsel: Crossfade des Inhalts, die Fläche morpht dabei auf die neue Inhaltshöhe.

---

## 7. Schließverhalten

- **Esc** schließt das offene Element.
- **Klick daneben** schließt ebenfalls. Umsetzung: ein transparentes
  Fullscreen-Layer-Shell-Fenster **unterhalb** der Leiste, das nur existiert, solange
  etwas offen ist. Ist nichts offen, darf es keine Klicks abfangen.
- Klick auf das offene Element selbst schließt es (Toggle), Klicks auf Bedienelemente
  darin natürlich nicht — das Event darf nicht bis zum Blob durchpropagieren.
- Klick auf ein anderes Element schließt das alte und öffnet das neue; beide
  Animationen laufen gleichzeitig, nicht nacheinander.
- Es ist immer höchstens **ein** Element geöffnet. Zentraler State in `BarState.qml`
  (`active: "none" | "left" | "calendar" | "launcher" | "right"`), nicht verstreute
  Booleans pro Komponente.

---

## 8. Theming (adaptiv über matugen)

- Farben kommen aus matugen, abgeleitet vom aktuellen Wallpaper.
- matugen-Template anlegen, das nach `~/.config/quickshell/bar/theme/colors.json`
  schreibt (Keys: background, surface, onSurface, primary, onPrimary, outline, error …).
- `Theme.qml` ist ein `Singleton`, liest die Datei per `FileView` mit
  `watchChanges: true` und aktualisiert die UI **live**, ohne Neustart der Shell.
- Farbwechsel animiert (`ColorAnimation`, ~300 ms), damit der Wallpaper-Wechsel weich wirkt.
- Kein einziger hartcodierter Hex-Wert in den Komponenten — alles über `Theme.*`.
- Die Transparenz aus Abschnitt 4 liegt als Alpha auf den Hintergrundfarben.

---

## 9. Qualitätsanforderungen

- Läuft mit `qs -p ~/.config/quickshell/bar` ohne Warnungen in der Konsole.
- Alle Morph-Animationen laufen flüssig, auch bei schnellem Hin- und Herklicken;
  eine unterbrochene Animation setzt sanft am aktuellen Wert an, statt zu springen.
- Keine Timer, wenn nichts sichtbar ist; alle Prozesse werden sauber beendet.
- Fehlt ein Tool (matugen, swww, PipeWire), degradiert die Shell sauber statt zu
  crashen — der betroffene Bereich zeigt einen Platzhalter.
- Kurze Kommentare nur dort, wo eine Quickshell-Eigenheit es erfordert.
- Am Ende: knappe README mit Abhängigkeiten, Start-Befehl und der Mango-Keybind-Zeile.
