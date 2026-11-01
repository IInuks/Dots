# Quickshell-Statusleiste im „Mr. Robot"-Stil

Ich nutze CachyOS mit Hyprland. Baue mir mit **Quickshell** (QML) eine Statusleiste mit Popup-Menüs. Vorlage ist ein Rice aus einem Video (Screenshot hänge ich an, falls vorhanden). Ziel: das Design so genau wie möglich treffen.

---

## 1. Vorgehen

1. Prüfe zuerst die Umgebung: installierte Quickshell-Version, ob `pipewire`, `upower`, `lm_sensors` und `curl` vorhanden sind, welche Schriften installiert sind (`fc-list`) und ob unter `~/.config/quickshell/` schon eine Config existiert.
2. Falls schon eine Config existiert: erst ein Backup anlegen, nichts ungefragt überschreiben.
3. Die Quickshell-API ändert sich zwischen Versionen. Richte dich nach der Doku der installierten Version (https://quickshell.org/docs/), nicht nach Gedächtnis.
4. Läuft bereits ein anderer Notification-Daemon (mako, dunst, swaync) oder eine andere Bar (z. B. waybar), sag mir Bescheid, bevor du etwas deaktivierst.
5. Baue schrittweise: erst die Bar ohne Popups, testen, dann ein Popup nach dem anderen. Nach jedem Schritt starten und die Logs auf Fehler prüfen.
6. Fehlende Pakete: nenne mir den Installationsbefehl (pacman/paru), installiere nichts ungefragt.

---

## 2. Design

**Gesamteindruck:** minimalistisch, dunkel, fast monochrom (Grau/Weiß), Hacker-Terminal-Look passend zu Mr. Robot. Keine Verläufe, kein Glow, keine bunten Akzente.

**Floating Islands:**
- Die Bar ist keine durchgehende Leiste, sondern besteht aus **drei separaten, schwebenden Inseln**: links, Mitte, rechts.
- Zwischen den Inseln ist das Wallpaper sichtbar – die Bar-Fläche selbst ist komplett transparent.
- Abstand zum oberen Bildschirmrand ca. 6 px, zu den Seitenrändern ca. 8 px.
- Höhe einer Insel ca. 28 px.
- Hintergrund der Inseln: sehr dunkles Grau, leicht transparent (ca. `#141619`, ~85 % Deckkraft).
- **Rahmen: 1 px**, helles Grau mit reduzierter Deckkraft (ca. `#8a8f98`, ~50 %) – klar sichtbar, aber dezent.
- Ecken: abgerundet, ca. 8 px Radius (nicht komplett pillenförmig).
- Innenabstand horizontal ca. 10 px, Abstand zwischen Modulen ca. 12 px.

**Schrift und Farben:**
- Kleine Monospace-Schrift (ca. 11–12 px), Textfarbe helles Grau (ca. `#c9ccd1`). Icons aus einer Nerd Font.
- Für große Anzeigen (z. B. die Uhr im Kalender-Popup) eine Pixel-/Bitmap-artige Schrift, falls installiert – sonst schlag mir eine vor.
- Farbe nur sparsam: Tray-Icons in Originalfarben, roter Punkt/Zähler bei Benachrichtigungen, sonst nur Graustufen.

**Zentrale Theme-Datei:** Alle Werte (Farben, Deckkraft, Radius, Rahmenbreite, Abstände, Höhe, Schriften) kommen in ein Singleton `Theme.qml`. Die Werte oben sind aus einem unscharfen Screenshot geschätzt – ich will sie später leicht feinjustieren können.

---

## 3. Aufbau der Leiste

Kein Logo- oder Launcher-Icon ganz links.

### Insel links
1. **CPU-Temperatur** – Thermometer-Icon + Wert (z. B. `76°C`). Klick öffnet den System-Monitor.
2. **Hyprland-Workspaces 1–5** – immer 1 bis 5 anzeigen. Aktiver Workspace hervorgehoben (hellerer Hintergrund mit eigenem dünnen Rahmen innerhalb der Insel), belegte Workspaces mit kleinem Punkt, leere nur als Zahl. Klick wechselt den Workspace, Mausrad blättert vor/zurück.
3. **System-Tray** – Icons der Tray-Apps. Linksklick aktiviert, Rechtsklick öffnet das Kontextmenü der App.
4. **Rundes Icon rechts neben dem Tray** – vorerst Platzhalter ohne Funktion. Frag mich, was es machen soll.

### Insel Mitte
5. **Uhrzeit** `HH:mm` – Klick öffnet Kalender & Wetter.
6. **Glocke** mit Zähler ungelesener Benachrichtigungen (Zähler nur sichtbar wenn > 0, rot markiert). Klick öffnet das Benachrichtigungsmenü.

### Insel rechts
7. **Akku** – Blitz-Icon beim Laden, sonst Akku-Icon, dazu Prozent. Ausblenden, wenn kein Akku vorhanden ist.
8. **Lautstärke** – Icon (Kopfhörer bei Kopfhörer-Ausgabe, sonst Lautsprecher, durchgestrichen bei Mute) + Prozent. Mausrad ±5 %, Mittelklick = Mute. Klick öffnet das Audio-Menü.
9. **Power-Button** – Klick öffnet das Power-Menü.

---

## 4. Popup-Menüs

### Für alle Popups gilt
- Gleicher Island-Stil wie die Bar (Hintergrund, 1-px-Rahmen, Radius, Schrift).
- Erscheinen direkt unter der angeklickten Insel mit ca. 6 px Abstand und ragen nie über den Bildschirmrand.
- Immer nur ein Popup gleichzeitig offen. Schließen durch erneuten Klick, Klick außerhalb (z. B. per `HyprlandFocusGrab`) oder Esc.
- Kurze, dezente Einblend-Animation (Deckkraft + leichtes Verschieben).

### Audio-Menü (Klick auf Lautstärke)
- **Ausgabegerät:** Liste aller Ausgabegeräte, aktuelles markiert, Klick setzt es als Standard.
- **Master-Lautstärke:** Slider + Mute-Button.
- **Mikrofon:** Eingabegerät-Auswahl, Slider + Mute.
- **Lautstärke pro Programm:** Liste aller Programme, die gerade Audio abspielen, jeweils mit App-Icon, Name, eigenem Slider und Mute-Button. Die Liste aktualisiert sich live, wenn Programme starten oder stoppen.
- Umsetzung über `Quickshell.Services.Pipewire` (Nodes an einen `PwObjectTracker` binden, damit Lautstärke-Werte verfügbar sind).

### Benachrichtigungsmenü (Klick auf Glocke)
- Quickshell übernimmt selbst die Rolle des Notification-Daemons (`NotificationServer`).
- Neue Benachrichtigungen erscheinen zusätzlich kurz als Toast oben rechts im gleichen Stil.
- Im Menü: Liste mit App-Icon, App-Name, Titel, Text und Uhrzeit. Jede einzeln schließbar, Aktions-Buttons falls die Benachrichtigung welche hat, Button „Alle löschen", Schalter „Nicht stören" (unterdrückt Toasts, Zähler läuft weiter).
- Öffnen des Menüs setzt den Zähler auf 0.

### Kalender & Wetter (Klick auf Uhr)
- Oben: große Uhr + Datum im Format `YYYY-MM-DD` mit Wochentag.
- **Monatskalender:** Woche beginnt am Montag, deutsche Wochentags-Kürzel, heutiger Tag hervorgehoben, Pfeile für vorherigen/nächsten Monat, Klick auf den Monatsnamen springt zurück zu heute.
- **Wetter:** aktuelle Temperatur in °C, Wetterzustand mit Icon, gefühlte Temperatur, Wind, dazu eine Vorschau für die nächsten Stunden und die nächsten 3 Tage.
- Datenquelle: Open-Meteo (kein API-Key nötig). Standort als Breiten-/Längengrad in der Config einstellbar – frag mich nach meinem Ort. Aktualisierung alle 15–30 Minuten; wenn offline, den letzten Stand mit Zeitstempel anzeigen.

### System-Monitor (Klick auf Temperatur)
- **CPU:** Gesamtauslastung in %, kleiner Verlaufsgraph der letzten ~60 Sekunden, Temperatur.
- **RAM:** belegt/gesamt mit Balken, dazu Swap.
- **GPU:** Auslastung und Temperatur, falls auslesbar (erkenne selbst, ob AMD, NVIDIA oder Intel).
- **Datenträger:** Belegung der Root-Partition.
- **Netzwerk:** aktuelle Upload-/Download-Rate.
- **Top 5 Prozesse** nach CPU-Last.
- Werte aus `/proc`, `/sys/class/hwmon` bzw. `sensors`. Den richtigen CPU-Sensor (z. B. `k10temp` oder `coretemp`) automatisch finden.
- Aktualisierung alle 1–2 Sekunden nur, solange das Popup offen ist. Die Temperatur in der Bar seltener (z. B. alle 3 Sekunden).

### Power-Menü (Klick auf Power-Button)
- Sperren, Abmelden, Bereitschaft, Neustart, Herunterfahren.
- Neustart und Herunterfahren mit Bestätigung.
- Zum Sperren `hyprlock` nutzen, falls installiert – sonst frag mich.

---

## 5. Dateistruktur

```
~/.config/quickshell/
├── shell.qml
├── Theme.qml                  (Singleton mit allen Design-Werten)
├── bar/
│   ├── Bar.qml
│   ├── Island.qml             (wiederverwendbare Insel-Komponente)
│   ├── Temperature.qml
│   ├── Workspaces.qml
│   ├── Tray.qml
│   ├── Clock.qml
│   ├── NotificationButton.qml
│   ├── Battery.qml
│   ├── Volume.qml
│   └── PowerButton.qml
├── popups/
│   ├── PopupBase.qml          (gemeinsame Popup-Basis)
│   ├── AudioMenu.qml
│   ├── NotificationCenter.qml
│   ├── CalendarWeather.qml
│   ├── SystemMonitor.qml
│   └── PowerMenu.qml
└── services/                  (Singletons für Wetter, Systemdaten, Benachrichtigungen)
```

Bei mehreren Monitoren: Bar auf jedem Monitor (über `Quickshell.screens`).

---

## 6. Zum Schluss

- Autostart über `exec-once` in `hyprland.conf` – zeig mir die Zeile, bevor du sie einträgst.
- Schlag mir passende Hyprland-Werte für Gaps und dünne graue Fensterrahmen vor, damit Fenster und Bar optisch zusammenpassen – nur als Vorschlag, nicht selbst ändern.
- Gib mir am Ende eine kurze Übersicht: welche Dateien angelegt wurden, wie ich die Shell neu lade und wo ich Farben und Abstände ändere.
