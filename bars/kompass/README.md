# kompass — Messgeräte-Panel-Bar für MangoWM

Quickshell-Leiste im Look eines analogen Instrumenten-/Messgeräte-Panels:
Zeigerinstrumente statt Text, geriffeltes Messing statt Glasoptik, Nieten an
den Panel-Ecken. Entstanden aus "überrasch mich mit einer Quickshell-Bar" —
voller Entwurf steht in [`CONCEPT.md`](CONCEPT.md) (übernimmt bei diesem
Projekt die Rolle des sonst vom Nutzer stammenden "Ursprungs-Prompt").

Stand: **Etappen 1–4 von 9 plus App-Launcher (Etappe 9) vorgezogen**
(Etappenplan in `CONCEPT.md`). Bar läuft, Kompassrose und
Temperatur-Zeigerinstrument sind live an echte Daten angebunden, Uhrzeit ist
noch Platzhaltertext statt der geplanten rollenden Ziffernwalze. App-Launcher
funktioniert per IPC und per echtem `SUPER+space` — `kompass` ist jetzt die
im Bar-Switcher registrierte, produktiv laufende Bar, siehe
"Mango-Keybind" unten. Per Screenshot auf der laufenden mango-Session
geprüft — siehe "Verifiziert" unten.

## App-Launcher

Klick auf die Uhrzeit (oder `SUPER+space`, sobald die Keybind-Zeile
eingetragen ist) öffnet ihn. Umsetzung folgt exakt dem in `bars/fisheye`
verifizierten Muster, nicht dem naiveren Ansatz aus `bars/blobs` (dessen
README den Tastatur-Fokus-Pfad selbst als "unverifiziert" markiert):

- Das Uhr-Modul in `Bar.qml` wächst von seiner Textbreite auf 130px
  (`Behavior on width`) und blendet von Uhrzeit auf ein Lupen-Glyph
  (`components/SearchGlyph.qml`) um — dadurch schiebt es die Trennlinie +
  Gauge nach rechts, und weil `panel` bildschirmzentriert bleibt, wandert
  die Kompassrose beim Wachsen sichtbar nach links. Kein Extra-Code für das
  "Schieben" nötig, das fällt aus Row + zentriertem Panel von selbst raus.
- Die eigentliche Sucheingabe + Ergebnisliste sitzt **nicht** in diesem
  Uhr-Modul, sondern in `LauncherWindow.qml`, einem eigenen, bei jedem
  Öffnen per `Loader` frisch erzeugten `PanelWindow` mit
  `WlrKeyboardFocus.OnDemand`. Grund: mango gewährt einer On-Demand-Surface
  Tastaturfokus nur beim allerersten Commit — ein wiederverwendetes,
  lediglich umgeschaltetes Fenster (wie `bar` selbst) bekommt ihn nie
  zuverlässig. `bars/fisheye/bar/LauncherWindow.qml` dokumentiert das im
  Detail; hier 1:1 übernommen statt den `blobs`-Bug zu wiederholen.
- `AppEntries.qml` (App-Scan) und `LauncherState.qml` (Routing der
  `SUPER+space`-IPC an die Bar des gerade fokussierten Monitors) sind
  unverändert aus `bars/fisheye` übernommen.
- `bar.launcherOpen` ist eine **lokale** Property pro Bar-Instanz, nicht in
  `BarState` — bei mehreren Monitoren (je einer `Bar` durch `Variants`)
  würde ein einziger globaler Bool den Launcher sonst überall gleichzeitig
  aufklappen.

**Mango-Keybind: scharfgeschaltet.** `kompass` ist jetzt als produktive Bar
registriert (`fullshell` lief zu dem Zeitpunkt nicht mehr, kein Konflikt):

- `quickdots/menu/adapters/kompass.json` angelegt (`hasLauncher: true` +
  die Keybind-Zeile), analog zu `blobs.json`/`fisheye.json`.
- `quickdots/menu/scripts/switch-bar.sh kompass` gelaufen — beendet die
  alte Bar sauber (per PID, kein `pkill -f`), startet `kompass` (idempotent
  dank `-n`), schreibt den `# >>> quickdots >>>`-Block in
  `~/.config/mango/config.conf` neu (mit Backup, `config.conf.bak-*`) und
  reloadet mango live per `mmsg dispatch reload_config`.
- `~/.config/mango/config.conf` bindet jetzt direkt:
  ```
  bind=SUPER,space,spawn,qs -p ~/quickdots/bars/kompass ipc call launcher toggle
  ```
  (vorher fiel es mangels Adapter-Eintrag auf `quickdots/menu`s generischen
  Such-Popup-Fallback zurück, `toggle-launcher.sh` — siehe Projekt-Notiz
  zum Bar-Switcher.)
- End-to-End per echtem IPC-Aufruf gegengeprüft (nicht nur inline): Uhr
  wächst, Kompass/Gauge weichen aus, Launcher-Fenster mit Ergebnisliste
  erscheint, `close` fährt sauber zurück.

## Woran als nächstes zu arbeiten ist

1. **Zeit-Trommel** (Etappe 5) — `Bar.qml`s Platzhalter-`Text` durch eine
   rollende Ziffernwalzen-Komponente ersetzen (siehe CONCEPT.md, Abschnitt
   "Zeit-Trommel"). Die Launcher-Breitenanimation greift denselben
   `clockModule`, also beim Umbau beachten, dass `width` weiterhin zwischen
   Ruhebreite und 130px umschaltbar bleibt.
2. **Audio-Popup** (Etappe 6) — Pipewire-Anbindung, Kippschalter/Drehregler.
3. **Netzwerk/Bluetooth-Popup** (Etappe 7).
4. **Power-Popup** (Etappe 8).
5. **Echte Tastatureingabe im Launcher-Suchfeld noch mit echter Tastatur
   gegenprüfen** — bisher nur per IPC-Zyklen (`toggle`/`close`) und
   Maus-Hover/-Klick auf Ergebniszeilen getestet, kein `wtype`/`ydotool` in
   dieser Umgebung verfügbar (dieselbe Lücke wie bei `bars/fisheye`).

Sobald Audio/Netzwerk/Power (Etappe 6-8) dazukommen, muss
`WlrLayershell.keyboardFocus` der Haupt-Bar von hartcodiert `None` auf einen
von `BarState.active` abhängigen Wert umgestellt werden (der Launcher selbst
braucht das nicht mehr, er hat sein eigenes Fenster).

## Kurzfassung

**Abhängigkeiten:**
- Quickshell 0.3.0 (geprüft)
- mango (liefert `mmsg` für Tags/Fokus — Kommandos in dieser Version:
  `get/watch all-monitors`, `get/watch focusing-client`,
  `dispatch viewcrossmon,...`; **nicht** die `-g -t`/`-w -t`-Form)
- `/sys/class/hwmon` mit `k10temp` (`Tctl`) für die CPU-Temperatur, optional
  `amdgpu` (`edge`) für später (GPU-Zeile ist noch nicht verbaut)
- pywal/shellwall (`~/.cache/wal/colors.json`) für die Palette — kein
  matugen-Template nötig, anders als bei `bars/blobs`

**Start:**
```
qs -p ~/quickdots/bars/kompass
```

Noch **kein** Mango-Keybind und **kein** Eintrag in
`quickdots/menu/adapters/` — die Bar ist noch nicht als Launcher-fähig
registriert (kommt erst mit Etappe 9). Bis dahin nur manuell mit obigem
Befehl starten, parallel zur produktiv laufenden `fullshell`-Bar (kollidiert
nicht, da kein Keybind beansprucht wird).

## Verifiziert

- `qs -p .` lädt ohne Warnungen (vorher zwei QML-Fallen erwischt und
  behoben, siehe "Stolperfallen" unten).
- Per `flameshot` auf der laufenden mango-Session gegengeprüft: Panel
  rendert mit allen vier Nieten, Kompassrose zeigt Tick-Punkte + Nadel +
  blauen Marker auf dem aktiven Tag, Uhrzeit korrekt, Temperatur-Instrument
  zeigt die grün/amber/rot-Zonenbögen und eine Nadel im plausiblen Bereich.
- Launcher per Screenshot bei `ipc call launcher toggle` gegengeprüft:
  Uhr-Modul wächst, blendet auf das Lupen-Glyph um, Kompassrose + Gauge
  weichen sichtbar aus, `LauncherWindow` erscheint zentriert darunter mit
  echter, live vom System gescannter App-Liste (`AppEntries.qml` fand u. a.
  Brave, btop++, ATLauncher). `ipc call launcher close` fährt beides sauber
  zurück, keine Warnungen im Log während der ganzen Sequenz.

## Stolperfallen

- **Repeater kann kein `ShapePath` erzeugen** — ein `Repeater { model: ...;
  ShapePath {...} }` innerhalb eines `Shape` schlägt mit "Delegate must be
  of Item type" fehl plus Folge-`TypeError`n, weil `ShapePath` kein `Item`
  ist. `components/Gauge.qml`s drei Zonenbögen sind deshalb drei feste,
  ausgeschriebene `ShapePath`-Elemente statt eines Repeaters (`root.zones`
  hat ohnehin immer genau 3 Einträge).
- **Property-Zugriff über die falsche ID** — in `Bar.qml`s Nieten-Repeater
  wurde `_inset` versehentlich als `panel._inset` referenziert (das
  Rectangle `panel` hat diese Property gar nicht, sie gehört dem
  Repeater-Delegate selbst) — Folge war ein stiller "Unable to assign
  undefined to x/y". Bare-Property-Referenz (`_inset` statt `panel._inset`)
  behoben.
- `MangoIpc.qml` und `Cpu.qml` sind unverändert aus `bars/fisheye` bzw.
  `bars/blobs` übernommen (dort schon gegen genau diese mmsg-Version bzw.
  hwmon-Belegung verifiziert) — nicht neu erfunden, um bekannte Fallen aus
  früheren Sessions nicht zu wiederholen.
