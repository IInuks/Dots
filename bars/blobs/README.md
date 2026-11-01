# blobs — Drei-Kugel-Leiste ohne Popups

Quickshell-Leiste für MangoWM aus genau drei schwebenden Elementen. Kein
separates Popup-Fenster: die drei Elemente selbst verformen sich beim
Anklicken von Kugel/Pille zu Menüfläche und zurück. Voller Auftrag steht
unten unter "Ursprungs-Prompt".

Stand: **Etappe 9 von 9 fertig — alle Etappen abgeschlossen.** Danach ein
Bugfix-Nachtrag (siehe "Nachtrag" ganz unten vor "Ursprungs-Prompt") für vier
vom Nutzer live gemeldete Probleme: Launcher öffnete nicht mit `SUPER,space`,
Wallpaper-Grid nicht scrollbar, Escape schloss nur den Launcher, keine Gap
oben (Fenster lagen unter der Bar).

## Kurzfassung

**Abhängigkeiten:**
- Quickshell ≥ 0.3.0
- mango (liefert `mmsg` für Tag-Status/-Wechsel)
- `awww` (Wallpaper-Backend — Upstream-Rename von `swww`, nixpkgs-Paket
  heißt weiterhin `pkgs.swww`)
- `matugen` (Farbpalette aus dem Wallpaper; Config unter
  `~/.config/matugen/`, siehe "Was funktioniert (Etappe 8)")
- Pipewire/wireplumber (Audio-Tab)
- `/sys/class/hwmon` mit `k10temp`- oder `coretemp`-Sensor (Ring), optional
  `amdgpu` für die GPU-Zeile im Systemmonitor-Tab

**Start:**
```
qs -p ~/quickdots/bars/blobs
```

**Mango-Keybind für den Launcher**: `SUPER,space` ruft
`qs -p ~/quickdots/bars/blobs ipc call launcher toggle` auf.
Nicht mehr manuell in `config.conf` einzutragen — `blobs` ist jetzt als
aktive Bar im `quickdots/menu`-Bar-Switcher registriert
(`quickdots/menu/adapters/blobs.json`, `hasLauncher: true` +
`keybinds`), der `config.conf`s `# >>> quickdots >>>`-Block automatisch
aus dieser Adapter-Datei schreibt (siehe `quickdots/menu/scripts/
switch-bar.sh`). Bei einem Wechsel auf eine andere Bar und zurück:
`quickdots/menu/scripts/switch-bar.sh blobs` erneut laufen lassen.
**Alter Konflikt (erledigt)**: Der Bind ging vorher gar nicht an `blobs`,
sondern an `quickdots/menu`s generischen App-Sucher (`SearchState.qml`),
weil `blobs` nie einen Adapter-Eintrag hatte — `fisheye`, mit dem hier
früher ein Konflikt vermutet wurde, läuft inzwischen gar nicht mehr
produktiv (siehe `ps aux`).

**Eine unverifizierte Stelle** (kein Input-Simulator wie `wtype`/`ydotool`
in dieser Umgebung — Details unten unter "Stolperfallen"/"Etappe 4"/"Etappe
8"):
- Echte Tastatureingabe im Launcher-Suchfeld (`WlrKeyboardFocus.Exclusive`
  auf einer wiederverwendeten Surface statt einem eigenen Fenster). Der
  Keybind selbst und der IPC-Toggle sind jetzt live verifiziert (siehe
  "Nachtrag" unten) — offen bleibt nur, ob echtes Tippen im Suchfeld
  ankommt.
- Der reale `awww`-Wallpaper-Wechsel durch Klick auf ein Thumbnail bleibt
  ebenfalls nicht ausgelöst (Desktop-Hintergrund des Nutzers soll nicht
  ungefragt geändert werden).

Alles andere in diesem Dokument ist das fortlaufende Etappen-Log des Baus
(Abweichungen vom Ursprungsauftrag, gefundene Stolperfallen, was in welcher
Etappe gebaut und wie verifiziert wurde) — nützlich zum Nachvollziehen von
Entscheidungen, nicht noetig, um die Bar zu benutzen.

## Woran als nächstes zu arbeiten ist

Kein offener Punkt aus dem ursprünglichen Etappenplan mehr. Mögliche
Nachträge, falls gewünscht (keiner davon Teil des Originalauftrags):
- Echte Tastatureingabe im Launcher-Suchfeld einmal mit echter Tastatur
  gegenprüfen, sobald ohne Risiko für den laufenden Desktop möglich (kein
  `wtype`/`ydotool` in dieser Umgebung).
- Den realen `awww`-Wallpaper-Wechsel durch Klick auf ein Thumbnail einmal
  auslösen, sobald der Nutzer das ausdrücklich möchte.

**Korrektur am eigenen Etappenplan:** Etappe 2 sollte laut ursprünglichem
Plan auch "Klick wechselt Tag" enthalten — das steht so aber nicht im
Auftrag (Abschnitt 4): die linke Kugel zeigt nur den aktiven Tag an, ein
Klick öffnet die Transparenz-/Wallpaper-Fläche (Etappe 4/8), sie ist kein
Tag-Umschalter. Deshalb in Etappe 2 nicht umgesetzt, um keine ungewollte
Funktion einzubauen.

## Abweichungen vom Ursprungs-Prompt (gegen die echte Umgebung verifiziert)

- **mmsg-Syntax**: Der Prompt nennt `mmsg -g -t`/`mmsg -w -t` — das gibt es
  nicht (`{"error":"unknown command"}`). Reale Kommandos (mango 0.16.1,
  bereits in `bars/fisheye/MangoIpc.qml` erprobt):
  `mmsg get all-monitors` / `mmsg watch all-monitors` liefert pro Monitor
  `tags: [{index, is_active, ...}]` + `active_tags: [...]`. Tag wechseln:
  `mmsg dispatch viewcrossmon,<index>,<monitor>`.
- **Wallpaper-Backend**: kein `swww`/`wpaperd` installiert. Läuft bereits als
  Daemon: `awww` (Upstream-Rename von swww, CLI 1:1 identisch —
  `awww img <pfad>`). Siehe `shellwall/README.md` für Details.
- **Wallpaper-Ordner**: `~/Pictures/Wallpaper` existiert nicht.
  Echter Ordner: `~/Pictures/Walpapers` (Tippfehler im Namen, 41
  Bilder, jpg/png gemischt).
- **matugen**: Binary vorhanden (Version 4.2.0), aber kein
  `~/.config/matugen/config.toml` — in Etappe 8 neu angelegt (siehe "Was
  funktioniert (Etappe 8)"), es gab nichts Bestehendes zum Wiederverwenden.
  `matugen image <pfad>` scheiterte anfangs mit "Multiple source colors
  found" bei mehrdeutigen Bildern — braucht `prefer = "..."` in `[config]`
  (config-weit) statt nur `--prefer` pro Aufruf, sonst haengt/scheitert der
  Aufruf aus `WorkspaceContent.qml` beim naechsten mehrdeutigen Bild ohne
  Terminal fuer eine interaktive Rueckfrage.
- **Sensoren**: `k10temp` → `Tctl` unter `/sys/class/hwmon/hwmon3/temp1_input`
  (Pfad kann sich nach Reboot ändern, Name `k10temp` ist stabil — Sensor beim
  Start über `*/name` auflösen, nicht hwmon3 hardcoden). Zusätzlich `amdgpu`
  → `edge` für optionale GPU-Temp in Tab 2 (Abschnitt 6).
- **Pipewire**: `Quickshell.Services.Pipewire` verfügbar, `Pipewire.
  defaultAudioSink` bereits in `bars/fisheye/bar/modules/VolumeModule.qml`
  erprobt.
- **DesktopEntries**: `fisheye` rollt bewusst einen eigenen `.desktop`-Scanner
  (`AppEntries.qml`) statt der echten `Quickshell.DesktopEntries`, mit
  Verweis auf Namens-/API-Inkonsistenz zwischen den bars dieses Repos.
  Trotzdem hier die echte `DesktopEntries` verwendet (Auftrag Abschnitt 5c
  verlangt sie explizit) — Shape gegen die tatsächlich installierten
  qmltypes verifiziert (nicht geraten):
  `quickshell-core.qmltypes`, `DesktopEntries.applications` (→ `.values`
  für die Liste), `DesktopEntries.byId(id)`, `DesktopEntry.name` /
  `.genericName` / `.icon` / `.noDisplay` / `.execute()`. Läuft sauber ohne
  Warnungen, siehe "Was funktioniert (Etappe 4)".

## Stolperfallen (für spätere Etappen im Kopf behalten)

- **Property-Name `error`** ist reserviert (kollidiert mit einem impliziten
  Signal) — `Cannot assign a value to a signal (expecting a script to be
  run)`. In `Theme.qml` deshalb `critical` statt `error`.
- **Property-Namen nach `/^on[A-Z]/`** (`onSurface`, `onPrimary`) werden von
  QML als Signal-Handler-Deklaration gelesen, nicht als Property — gleicher
  Fehler wie oben. In `Theme.qml` deshalb `surfaceInk`/`primaryInk` statt
  `onSurface`/`onPrimary` (Konvention aus `bars/fisheye/Theme.qml`
  übernommen).
- **Singleton-Importe**: `Theme.qml` bleibt root-level. Jede Datei unter
  `components/`, `content/` erreicht es über einen reinen `".."`-Import.
  Ein seitlicher/symlink-Import eines `pragma Singleton` liefert sonst
  überall `undefined`, ohne Fehlermeldung (siehe fisheye-README, Stolperfalle
  1 — gilt hier genauso).
- **`Quickshell.DesktopEntries` — kein `Quickshell.`-Präfix**: Das
  eingebaute Singleton ist nach dem `import Quickshell` unter seinem bloßen
  Typnamen `DesktopEntries` erreichbar, nicht als `Quickshell.
  DesktopEntries` — Letzteres liefert `undefined` und einen Laufzeitfehler
  (`Cannot read property 'applications' of undefined`), keinen Lade-/
  Compile-Fehler. Per Fehlermeldung gefunden, in `LauncherContent.qml`
  korrigiert. Nicht zu verwechseln mit der in `fisheye/AppEntries.qml`
  dokumentierten Shadowing-Falle (eigenes Singleton _mit_ diesem Namen) —
  hier ist es der umgekehrte Fehler, ein zu viel geschriebenes Präfix vorm
  echten eingebauten Typ.
- **`WlrKeyboardFocus.Exclusive` auf wiederverwendeter Surface —
  unverifiziert**: `Bar.qml` schaltet `keyboardFocus` je nach
  `middleBlob.mode` zwischen `None` und `Exclusive` um, auf derselben seit
  Start laufenden `PanelWindow` (kein Loader/neue Surface). `fisheye` hat
  mit `WlrKeyboardFocus.OnDemand` auf genau diesem Weg echte Tastatureingabe
  nie zum Laufen gebracht (mango vergibt On-Demand-Fokus nur beim allerersten
  Commit einer Surface oder bei einem bereits als On-Demand committeten
  Klick) und musste dafür dem Launcher ein eigenes, per Loader neu
  erzeugtes Fenster geben (`fisheye/bar/LauncherWindow.qml`). Das verbietet
  der Auftrag hier ausdrücklich ("zu keinem Zeitpunkt erscheint ein
  separates Fenster") — deshalb bewusst trotzdem der direkte Weg auf der
  bestehenden Surface, mit `Exclusive` statt `OnDemand` (Auftrag Abschnitt
  5c schreibt `Exclusive` vor, das ist nicht click-basiert wie `OnDemand`
  und könnte deshalb funktionieren). **Nicht mit echter Tastatur
  gegengeprüft** — kein `wtype`/`ydotool` in dieser Umgebung (wie schon bei
  fisheye). Bei Gelegenheit mit echter Tastatur testen: `SUPER,space` (oder
  die IPC-Variante) auslösen, tippen, `Escape`. Falls es doch nicht
  funktioniert, gibt es innerhalb der "kein separates Fenster"-Regel keinen
  Ausweg außer einem echten Bugreport/Workaround auf mango-Seite.
- **Screenshot machen**: kein `grim` im System, ad-hoc per `nix shell` holen
  (siehe `bars/fisheye/README.md`, Abschnitt "Screenshot machen"):
  ```
  qs -p . > /tmp/live.log 2>&1 &
  QSPID=$!
  sleep 2
  nix --extra-experimental-features "nix-command flakes" shell nixpkgs#grim \
    --command grim /tmp/screenshot.png
  kill $QSPID
  sleep 0.5
  ps aux | grep quickshell   # sicherstellen, dass der Testprozess wirklich weg ist
  ```

## Konventionen

- Kein Hex-Wert, keine Dauer/Easing außerhalb von `Theme.qml`.
- Neue Theme-Property → sofort gegen `/^on[A-Z]/` und den reservierten Namen
  `error` prüfen (s.o.).
- Neue Datei in `components/`/`content/`, die `Theme` (oder später `Mango`,
  `BarState`, `Settings`, `Cpu`) braucht → Import muss eine reine
  `".."`-Kette zum `blobs/`-Root sein.
- `QtQuick.Shapes`/`ShapePath`/`PathAngleArc` für den Temperatur-Ring
  (Etappe 5) — kein gedrehtes Canvas.
- Jede Etappe muss `qs -p .` warnungsfrei laden, bevor sie als fertig gilt.

## Was funktioniert (Etappe 1)

- `Theme.qml` — Singleton, hartcodierte Fallback-Palette (`background`,
  `surface`, `surfaceInk`, `primary`, `primaryInk`, `outline`, `critical`)
  plus Geometrie-Konstanten (`barHeight: 46`, `pillWidth: 118`, `gap: 12`,
  `topMargin: 8`). Wird in Etappe 8 durch echtes matugen-Live-Reload ersetzt
  bzw. erweitert — bis dahin die einzige Quelle für Farben/Maße.
- `shell.qml` — `ShellRoot` mit `Variants` über `Quickshell.screens`,
  instanziiert `Bar` pro Monitor.
- `Bar.qml` — `PanelWindow`, `anchors.top/left/right`, `exclusiveZone: 0`
  (schwebt über den Fenstern, reserviert keinen Platz — Auftrag Abschnitt 2),
  `WlrLayershell.layer: Top`, `namespace: "blobs-bar"`,
  `keyboardFocus: None` (kein Popup existiert noch). `mask: Region` referenziert
  exakt die drei Blob-Items, keine größere Fläche fängt Klicks ab.
  Positionierung über Anchors statt manueller Pixel-Rechnung: mittlere Pille
  `anchors.horizontalCenter: parent.horizontalCenter`, beide Kugeln
  `anchors.right/left: middleBlob.left/right` + `Theme.gap` — erfüllt die
  Formel aus Abschnitt 2 automatisch und bleibt auch bei einem breiter
  werdenden mittleren Blob (Etappe 3+) korrekt, ohne dass die Positions-
  Logik angefasst werden muss.
- `components/WorkspaceBlob.qml`, `ClockBlob.qml`, `TempBlob.qml` — je ein
  `Rectangle` mit `radius: height/2` (Ruhezustand: perfekte Kugel/Pille),
  statischer Platzhalter-Inhalt ("1", "12:34", "55°"). Keine Morph-Logik,
  keine echten Datenquellen — beides kommt in späteren Etappen.

Getestet mit `qs -p .` — lädt sauber, keine Warnungen (`INFO: Configuration
Loaded`, kein `ERROR`). **Per Screenshot visuell verifiziert**: die drei
Elemente schweben korrekt zentriert am oberen Bildschirmrand, exakt
symmetrisch um die Bildschirmmitte, 12px Lücke zwischen Pille und Kugeln,
beide Kugeln gleich groß.

## Was funktioniert (Etappe 2)

- `Mango.qml` — Singleton, `mmsg watch all-monitors` als Dauerprozess
  (`Process`/`SplitParser`), Neustart nach 1s bei Absturz. Kein separater
  `get`-Aufruf für den Initialwert nötig — `watch` liefert beim Start sofort
  eine erste Zeile mit dem aktuellen Zustand. `monitorFor(screenName)` und
  `activeTagFor(screenName)` (0, solange noch keine Daten da sind).
- `WorkspaceBlob.qml` bekommt `outputName` von `Bar.qml` (`bar.screen.name`)
  und zeigt `Mango.activeTagFor(outputName)` statt des Platzhalters — "–"
  solange kein Wert da ist. Tag-Wechsel animiert (Fade 0→1 + 2px
  Anker-Offset-Slide in Wechselrichtung, beides eigenständige
  `NumberAnimation`s statt `Behavior`, damit der anfängliche Direktsprung auf
  den Startversatz nicht selbst mitanimiert wird).
- **Live verifiziert** (nicht nur durch fehlerfreies Laden): Bar gestartet,
  Screenshot, per `mmsg dispatch viewcrossmon,3,DP-4` den Tag von 1 auf 3
  gewechselt, zweiter Screenshot — Kugel zeigt "3" statt "1"
  (`mmsg get all-monitors` bestätigt `last_open_surface: "blobs-bar"`, die
  Leiste läuft also wirklich als eigene Layer-Surface, nicht nur im Log).
  Danach Tag per `viewcrossmon,1,DP-4` zurückgesetzt und Testprozess beendet.

## Was funktioniert (Etappe 3)

- `components/MorphBlob.qml` — Basiskomponente aller drei Blobs.
  `width`/`height` per `Behavior` zwischen Ruhe- und Ziel-Größe (380ms
  öffnend / 300ms schließend, `Easing.OutCubic`), `radius` separat und
  minimal schneller (340ms öffnend), damit die Form früh "zur Fläche wird"
  (Auftrag Abschnitt 3). `clip: true` auf der Fläche selbst.
  - **Kopfzeile bleibt pixelfest**: `iconHolder` ist genau `restWidth` breit
    (nicht die volle wachsende Breite) und hängt per `iconAnchor`
    (`"left"`/`"center"`/`"right"`, per `States`+`AnchorChanges`) an genau
    der Kante, die beim Wachsen fix bleibt — links wächst nach links, also
    hängt das Symbol rechts fest, und umgekehrt rechts. Dadurch wandert das
    Kopfzeilen-Symbol beim Öffnen keinen Pixel, unabhängig davon, wie breit
    die Fläche wird.
  - **Body-Fade**: öffnend 220ms Opacity-Animation mit 160ms
    `PauseAnimation` davor; schließend springt `bodyContainer.opacity`
    sofort auf 0, kein Fade — beides über eigenständige Animationen aus
    `onOpenChanged` gestartet, keine `Behavior` (die würde auch den
    Sofort-Sprung beim Schließen mitanimieren).
  - **Kein eigenes Öffnen/Schließen-Verhalten** — `MorphBlob` emittiert nur
    `clicked()` (Klick auf `iconHolder`), der Konsument entscheidet, was das
    bedeutet. Gleiches Prinzip wie `bars/fisheye/bar/modules/ClockModule.qml`.
- **Emergente Eigenschaft aus Etappe 1 bestätigt**: weil `Bar.qml` die
  Kugeln bereits über `anchors.right: middleBlob.left` /
  `anchors.left: middleBlob.right` positioniert (statt fester Pixel-Werte),
  schiebt ein wachsender mittlerer Blob die Kugeln automatisch nach außen,
  exakt synchron zur selben `width`-Animation — ganz ohne eigene
  Schiebe-Logik. Kein Code in `Bar.qml` musste für Etappe 3 angefasst
  werden.
- `components/ClockBlob.qml` nutzt jetzt `MorphBlob`: echte Uhrzeit per
  `SystemClock` (`precision: Minutes`, aktualisiert exakt auf die volle
  Minute, kein Timer/Polling), `font.family: "monospace"` statt eigener
  Ziffernbreite-Logik gegen Springen. `bodyData` zeigt einen Platzhalter-Text
  ("Kalender-Platzhalter (Etappe 4)") — echter Kalender-Inhalt kommt in
  Etappe 4. `openWidth`/`openHeight` (282×104) sind bereits die echte
  Zielgröße aus Auftrag Abschnitt 5b, keine Zwischengröße.
- `Theme.maxPanelHeight` (256, größte aller "Geöffnet"-Größen aus Abschnitt
  4/5/6) + `Bar.qml`s `implicitHeight` darauf angehoben — sonst würde jede
  offene Fläche am Fensterrand abgeschnitten. Die `mask` aus Etappe 1 fängt
  den dadurch entstehenden Leerraum weiterhin nicht ab (referenziert weiter
  nur die drei Blob-Items selbst).
- `WorkspaceBlob`/`TempBlob` bewusst unverändert (noch reine `Rectangle`s,
  keine `MorphBlob`) — die Mechanik wird laut Plan erst an einem Blob
  verifiziert, bevor sie kopiert wird; das passiert für die Kugeln in
  Etappe 4/5, wenn ihr echter Menü-Inhalt ansteht.

**Live verifiziert** (nicht nur fehlerfreies Laden): `isOpen` in
`ClockBlob.qml` temporär auf `true` gesetzt (kein `wtype`/`ydotool` in
dieser Umgebung, siehe fisheye-README), Screenshot — Uhrzeit blieb exakt an
Ort und Stelle, Radius ging zu abgerundetem Rechteck über, beide Kugeln
rückten sichtbar nach außen. Danach zurück auf `false`, zweiter Screenshot
bestätigt sauberen Ruhezustand (echte Uhrzeit statt Platzhalter, alle drei
Blobs wieder in Normalgröße/-position), Testprozess beendet.

## Was funktioniert (Etappe 4)

- `components/MorphBlob.qml` um `headerWideData` erweitert: ein zweiter,
  voll-breiter Kopfzeilen-Slot (rendert über `iconHolder`) für Fälle, in
  denen das Symbol selbst ersetzt wird statt nur ergänzt zu werden
  (Launcher-Suchfeld statt Uhrzeit). `iconHolder` bleibt unverändert für
  den Fall, dass nur zusätzlicher Inhalt daneben erscheint (Kalender-Modus:
  Uhrzeit bleibt stehen).
- `content/CalendarContent.qml` — sieben Wochentage Mo–So, aktueller Tag
  (`clock.date.getDay()`, `(getDay()+6)%7` für Mo-So-Reihenfolge) mit
  gefülltem `Theme.primary`-Hintergrund hervorgehoben.
- `content/LauncherContent.qml` — echte `DesktopEntries.applications.values`,
  eigene Fuzzy-Score-Funktion (Präfix > frühe Teilzeichenkette > Buchstaben-
  Subsequenz > kein Treffer), Name- und `genericName`-Treffer beide
  berücksichtigt, `genericName`-Treffer leicht niedriger gewichtet, Top 6
  nach Score sortiert. `moveSelection()`/`activateSelected()` von außen
  aufrufbar (Pfeiltasten/Enter sitzen im Suchfeld in der Kopfzeile, nicht
  in der Ergebnisliste selbst). Icons über `Quickshell.iconPath(icon,
  fallback)`.
- `components/ClockBlob.qml`: `mode` ("none"/"calendar"/"launcher") ersetzt
  den lokalen `isOpen`-Bool aus Etappe 3 — Kalender und Launcher teilen sich
  dieselbe Fläche/denselben State, kein zusätzlicher Bool nötig. Klick auf
  Uhrzeit/Suchfeld öffnet Kalender bzw. schließt, was offen ist. Header
  crossfaded zwischen Uhrzeit und Lupe+Textfeld (`Theme.durCrossfade`,
  180ms). `LauncherState`-Pulses nur verarbeitet, wenn `outputName ===
  Mango.focusedMonitorName` (Mango.qml jetzt mit `focusedMonitorName`, aus
  den ohnehin schon gestreamten `all-monitors`-Daten, keine neue IPC nötig)
  — verhindert, dass der Hotkey auf jedem Monitor gleichzeitig öffnet.
- `LauncherState.qml` (Singleton) + `IpcHandler` in `shell.qml` (`qs -p .
  ipc call launcher toggle/open/close`) — 1:1 dasselbe Relais-Prinzip wie
  `fisheye/LauncherState.qml`.
- `Bar.qml`: `WlrLayershell.keyboardFocus` folgt jetzt `middleBlob.mode ===
  "launcher"` (`Exclusive`/`None`) statt fest auf `None` — **siehe
  "Stolperfallen" oben, unverifiziertes Risiko**, da dies auf derselben
  langlebigen Surface passiert, für die `fisheye` mit `OnDemand` genau
  daran gescheitert ist.

**Live/visuell verifiziert** (nicht nur fehlerfreies Laden): `ClockBlob`s
`mode` und `query` nacheinander temporär auf `"calendar"`, dann
`"launcher"` + `"br"` gesetzt (kein `wtype`/`ydotool` in dieser Umgebung),
je ein Screenshot:
- Kalender: Uhrzeit blieb in der Kopfzeile stehen, sieben Wochentage
  erschienen, "So" (13.09.2026 ist ein Sonntag) korrekt hervorgehoben.
- Launcher: Kopfzeile crossfadete zu Lupe+"br", Ergebnisliste zeigte echte
  installierte Apps ("Brave Web Browser" ganz oben und markiert — Präfix-
  Treffer schlägt Substring-/Subsequenz-Treffer wie "Kerbal Space
  Program" —, echte Icons geladen).

Danach `mode`/`query` zurück auf `"none"`/`""`, erneuter Screenshot
bestätigt sauberen Ruhezustand, Testprozess jedes Mal beendet.
**Nicht verifiziert**: echte Tastatureingabe im Suchfeld (Tippen, Pfeiltasten,
Enter, Escape) — siehe "Stolperfallen" oben.

## Was funktioniert (Etappe 5)

- `Cpu.qml` (Singleton) — Sensor-Pfad einmal beim Start per `sh -c`-Scan
  aufgeloest (`/sys/class/hwmon/*/name` nach `k10temp`/`Tctl` bzw.
  `coretemp`/`Package id 0` durchsucht, `hwmon3` auf diesem System, aber
  nicht hartcodiert — Nummerierung ist nicht garantiert stabil ueber einen
  Reboot). Danach nur noch `FileView` + `Timer` (2s, `triggeredOnStart:
  true` fuer den sofortigen ersten Wert) — kein Shell-Prozess im
  Polling-Loop, wie im Auftrag gefordert. `FileView`-API (`reload()`,
  `text()`, `loaded`-Signal, `path`-Property) gegen `quickshell-io.
  qmltypes` + die echte `FileView.qml`-Wrapper-Datei verifiziert, nicht
  geraten.
- `components/TempRing.qml` — `Shape`/`ShapePath`/`PathAngleArc`, zwei
  uebereinanderliegende Boegen (voller Track in `Theme.outline`, gefuellter
  Teil in Statusfarbe). Winkel-Formel hergeleitet: Qt-Konvention 0°=3-Uhr,
  positiv=im Uhrzeigersinn, `winkel(stunde) = stunde/12*360 - 90` →
  8 Uhr = 150°, 4 Uhr = 30°; `startAngle: 150, sweepAngle: 240` läuft von
  150° im Uhrzeigersinn ueber 180°/270°/0°(9/12/3 Uhr) exakt auf 30° (4 Uhr)
  — 120° Luecke unten wie gefordert. Ring bleibt innerhalb der 46×46 (Radius
  = halbe Kugelgroesse minus Strichstaerke), macht die Kugel nicht groesser.
  `progress`/`statusColor` beide mit `Behavior` (400ms), kein Umspringen.
- `components/TempBlob.qml` — Skala 30–95°C linear geklemmt
  (`Math.max`/`Math.min`), Farbstufen gruen (≤65°C) / amber (≤80°C) / rot
  (`Theme.critical`, > 80°C) aus `Theme.tempGood`/`tempWarn`/`critical`.
  "--°" solange `Cpu.sensorFound` noch `false` ist. **Noch kein
  `MorphBlob`** — Audio-/Systemmonitor-Inhalt (Auftrag Abschnitt 6,
  "Geöffnet") kommt erst in Etappe 6/7, dann wird `TempBlob` genauso auf
  `MorphBlob` umgestellt wie `ClockBlob` in Etappe 3.

**Live verifiziert** (nicht nur fehlerfreies Laden): Screenshot bei echter
Sensortemperatur (52–53°C laut `cat /sys/class/hwmon/hwmon3/temp1_input`
zum Zeitpunkt des Tests) — Kugel zeigte "53°", grüner Teilbogen sichtbar,
beginnt bei der 8-Uhr-Position und läuft im Uhrzeigersinn nach oben, Kugel
bleibt in Originalgröße. Dabei ein Nebenbefund: ein Vollbild-Client
(`is_fullscreen: true`, per `mmsg get focusing-client` bestätigt) deckte
die gesamte Top-Layer-Fläche ab und machte die Bar auf dem ersten Screenshot
unsichtbar — kein Bug, exakt das in `fisheye/README.md` dokumentierte
wlroots-Verhalten. Für den Screenshot kurz auf einen anderen Tag gewechselt
(`mmsg dispatch viewcrossmon,2,DP-4`) und danach zurück auf Tag 1
(`viewcrossmon,1,DP-4`) — dabei zwischenzeitlich auf Tag 2 stehen
geblieben (Ursache nicht geklärt, evtl. Race mit dem laufenden Testprozess),
beim Nachpruefen bemerkt und sofort korrigiert.

## Was funktioniert (Etappe 6)

- `components/MorphBlob.qml` um `labelData` erweitert: dritter Kopfzeilen-
  Slot fuer eine Zusatzbeschriftung neben dem fixen Symbol (Auftrag
  Abschnitt 3 nennt "Workspace" und "CPU-Temperatur" als Beispiele — beide
  Kugeln brauchen das, deshalb generisch in `MorphBlob` statt in
  `TempBlob` dupliziert). Sitzt automatisch auf der Seite, zu der hin
  gewachsen wird (`iconAnchor: "left"` → Beschriftung rechts, `"right"` →
  links, per `States`+`AnchorChanges` wie schon `iconHolder`), blendet
  zeitgleich mit `bodyData` ein (`ParallelAnimation` in derselben
  `SequentialAnimation`, gleicher Delay).
- `content/AudioContent.qml` — Master-Lautstärke (Mute-Icon-Toggle,
  Slider, Prozentwert) + pro-Stream-Slider. `Quickshell.Services.Pipewire`-
  Nutzung (`Pipewire.defaultAudioSink`, `Pipewire.nodes.values`,
  `PwObjectTracker`, `node.audio.volume`/`.muted`, Stream-Filter über
  `PwNodeType.AudioOutStream`) 1:1 aus dem produktiv laufenden
  `bars/fisheye/menus/SoundMixerMenu.qml` übernommen, nur die Optik auf
  `Theme.qml`-Farben und einen selbst gebauten Schieberegler umgestellt
  (kein `QtQuick.Controls.Slider` — kein bar in diesem Repo nutzt das,
  alle rollen einen eigenen `MouseArea`+`Rectangle`-Slider, z.B.
  `bars/quickbar/Slider.qml`; hier direkt inline in `AudioContent.qml`
  gehalten statt einer eigenen Datei, da nur an zwei Stellen gebraucht).
- `components/TempBlob.qml` jetzt `MorphBlob`-basiert (`iconAnchor:
  "left"`, `openWidth/Height: 268×232` aus Auftrag Abschnitt 6, schon die
  echte Zielgröße). Klick auf Ring+Zahl togglet `isOpen`, genau wie bei
  `ClockBlob`. Einfache Tab-Leiste ("Audio"/"System") in `bodyData`,
  Inhalt crossfaded (`Theme.durCrossfade`). "System"-Tab noch Platzhalter
  (Etappe 7).

**Live verifiziert** (nicht nur fehlerfreies Laden): `isOpen` temporär auf
`true` gesetzt, Screenshot — Ring+"54°" blieben oben links stehen,
Beschriftung "CPU-Temperatur" blendete rechts daneben ein, Audio-Tab zeigte
einen Master-Slider bei "22%". Per `wpctl get-volume @DEFAULT_AUDIO_SINK@`
gegengeprüft: reale Systemlautstärke war exakt `0.22` — die Pipewire-
Anbindung liefert also echte Live-Daten, keine Platzhalterwerte. Danach
`isOpen` zurück auf `false`, zweiter Screenshot bestätigt sauberen
Ruhezustand aller drei Blobs, Testprozess jedes Mal beendet.

## Was funktioniert (Etappe 7)

- `Cpu.qml` um GPU-Temperatur erweitert (`amdgpu`/`edge`, gleiches
  Aufloese-/Poll-Prinzip wie CPU, eigener Sensor-Pfad + eigene `FileView`,
  ein gemeinsamer `Timer` pollt beide). Kein neues Singleton dafuer
  angelegt — `Cpu.qml` war ohnehin schon "die hwmon-Sensor-Stelle", eine
  zweite fast identische Datei nur fuers GPU waere reine Duplikation
  gewesen.
- `content/SystemContent.qml` — `required property bool active` steuert
  einen eigenen `Timer` (2s, `triggeredOnStart`) direkt in diesem Content,
  nicht global: pollt wirklich nur, wenn der System-Tab sichtbar UND der
  Blob offen ist, exakt wie im Auftrag gefordert ("kein Timer im
  Leerlauf"). CPU-Auslastung und Netzwerk-Durchsatz brauchen je zwei
  aufeinanderfolgende Messpunkte (Differenz durch die seit dem letzten Tick
  vergangene Zeit) — `_prevCpu`/`_prevNet` werden beim Unsichtbarwerden
  (`onActiveChanged`) zurueckgesetzt, damit ein Wiederoeffnen nach langer
  Pause nicht faelschlich eine riesige Lastspitze anzeigt. GPU-Zeile nur
  im Modell, wenn `Cpu.gpuSensorFound` true ist (Auftrag: "nur wenn Sensor
  vorhanden") — kein Platzhalter-Strich, die Zeile fehlt komplett.
  `/proc/stat`/`/proc/meminfo`/`/proc/net/dev`/`/proc/uptime`-Formate vorab
  live gegengelesen (nicht geraten), z.B. `/proc/net/dev`s Spaltenzahl (8
  Empfangs-Spalten vor der ersten Sende-Spalte) und `/proc/stat`s
  Feldreihenfolge (`user nice system idle iowait ...`).
- `components/TempBlob.qml`: `openHeight` haengt jetzt von `tab` ab (190
  fuer System, 232 fuer Audio aus Auftrag Abschnitt 6) — Tab-Wechsel morpht
  die Flaeche wirklich auf die neue Inhaltshoehe, nicht nur der Inhalt
  crossfaded. Der erste Versuch (150 fuer System) war zu knapp und hat die
  Uptime-Zeile abgeschnitten (durch `clip: true` auf der `MorphBlob`-Fläche
  unsichtbar statt sichtbar-falsch) — per Screenshot bemerkt und auf 190
  korrigiert.

**Live verifiziert** (nicht nur fehlerfreies Laden): `isOpen`/`tab` temporär
auf `true`/`"system"` gesetzt, Screenshot — alle fuenf Zeilen sichtbar (CPU
9%, RAM 4.4/30.5 GiB, GPU 48°, Netz 0/0 KB/s, Uptime 2h 46m). Gegen echte
Werte gegengeprüft: `free -g` bestätigt ~30 GiB/~4 GiB, `awk` auf
`/proc/uptime` liefert dieselbe Stunden/Minuten-Rechnung, und ein manuelles
Vorher/Nachher auf `/proc/net/dev` (`eno1`) ergab ~0.2 KB/s reale Last —
"0/0 KB/s" ist also die korrekt gerundete Wahrheit, kein Bug. Netzwerkwert
zusätzlich nach 4s erneut geprüft, um die Delta-Berechnung über die Zeit zu
bestätigen (nicht nur einen Einzelwert). Danach `isOpen`/`tab` zurück auf
`false`/`"audio"`, Testprozess beendet.

## Was funktioniert (Etappe 8)

- **matugen-Setup neu angelegt** (existierte nicht):
  `~/.config/matugen/config.toml` mit `[config]` (`prefer =
  "closest-to-fallback"`, `fallback_color`), `[config.wallpaper]`
  (`command = "awww img {{ image }}"` — matugen setzt das Wallpaper damit
  selbst, ein Aufruf statt zwei) und `[templates.blobs-bar]`
  (`~/.config/matugen/templates/blobs-colors.json` →
  `~/.cache/blobs-bar/colors.json`). Template-Syntax (`{{colors.primary.
  default.hex}}` usw.) nicht geraten, sondern aus dem echten Beispiel im
  matugen-Repo (`example/config.toml` auf GitHub) übernommen, nachdem der
  erste Versuch ohne `[config]`-Sektion mit einer klaren Fehlermeldung samt
  Doku-Link scheiterte. Rollennamen (`background`, `on_surface`, `primary`,
  `on_primary`, `outline`, `error`) per `matugen image ... -j hex` echt
  ausgelesen, nicht aus der Erinnerung zusammengereimt.
- `Theme.qml` liest jetzt `~/.cache/blobs-bar/colors.json` live
  (`FileView`, `watchChanges: true`), fällt auf die bisherige
  Fallback-Palette zurück, solange die Datei fehlt oder kaputt ist. Jede
  Farbe hat eine `Behavior { ColorAnimation { duration: 300 } }` (Auftrag
  Abschnitt 8). **Stolperfalle dabei**: ein bare `FileView { ... }` direkt
  als Kind von `QtObject` scheitert mit "Cannot assign to non-existent
  default property" (`QtObject` hat keine Default-Property) — musste wie
  überall sonst in diesem Projekt als benannte `property FileView x:
  FileView {...}` geschrieben werden.
- `content/WorkspaceContent.qml` — Transparenz-Slider (0–100 %, eigener
  Mini-Slider wie schon in `AudioContent.qml`) + Wallpaper-Grid (`ls`
  einmalig über den echten Ordner, gefiltert auf jpg/jpeg/png/webp, `Image`
  mit `asynchronous: true` + kleiner `sourceSize` fürs Thumbnail-Caching).
  Klick auf ein Bild ruft nur `matugen image <pfad>` auf — Wallpaper setzen
  passiert dank `[config.wallpaper]` gleich mit, kein separater
  `awww`-Aufruf nötig, Theme übernimmt die neue Palette automatisch.
- `components/WorkspaceBlob.qml` jetzt `MorphBlob`-basiert (`iconAnchor:
  "right"`, `openWidth/Height: 268×256` aus Abschnitt 4) — Tag-Zahl bleibt
  beim Öffnen pixelfest oben rechts stehen, Beschriftung "Workspace"
  erscheint links davon (Abschnitt 3 nennt "Workspace" explizit als
  Beispiel für `labelData`, dieselbe Mechanik wie bei `TempBlob`).
- **`BarState.qml`** (neues Singleton) ersetzt die bisherigen drei
  unabhängigen lokalen States (`WorkspaceBlob`s künftiges `isOpen`,
  `ClockBlob`s `mode`, `TempBlob`s `isOpen`) durch einen einzigen
  `active`-Wert (`"none"|"left"|"calendar"|"launcher"|"right"`) — erfüllt
  Abschnitt 7 ("immer höchstens ein Element offen") direkt durch die
  Datenstruktur, nicht durch verstreute Bedingungen. `toggle(name)` deckt
  beide Fälle aus Abschnitt 7 gleichzeitig ab: gleicher Name → schließen,
  anderer Name → direkt umschalten (kein Umweg über "none", `MorphBlob`s
  `Behavior`s interpolieren das ohnehin sauber). `ClockBlob`s `mode` ist
  jetzt aus `BarState.active` abgeleitet (`readonly property`) statt
  eigenständig.
- **Klick-daneben-Schließen**: `Bar.qml` bekommt eine `outsideCloseArea`
  (volle Fensterbreite/-höhe, Höhe kollabiert auf 0 wenn nichts offen ist —
  exakt der Trick aus `bars/fisheye/bar/Bar.qml`), als vierte `Region` in
  der `mask`, vor den drei Blobs deklariert, damit deren eigene Klickflächen
  bei Überlappung Vorrang haben (spätere Geschwister liegen in QtQuick
  oben).
- **`Escape` nur im Launcher verdrahtet** (`Keys.onEscapePressed` im
  Suchfeld, ruft `BarState.close()`), nicht für Kalender/Wallpaper/Audio —
  die halten laut Auftrag nie Keyboard-Fokus (nur der Launcher bekommt
  `Exclusive`), ein globales Escape ohne jeden Fokus ist über
  Wayland/Layer-Shell nicht sauber abzufangen. Klick-daneben und
  Klick-auf-das-offene-Element-selbst decken das Schließen für diese drei
  ab.
- `Bar.qml` selbst hat kein `opacity` (Laufzeitfehler "Cannot assign to
  non-existent property" — `PanelWindow` ist kein `Item`) — die drei Blobs
  stecken deshalb in einem eigenen `Item` (`blobsLayer`), dessen `opacity`
  an `Settings.barOpacity` hängt; `outsideCloseArea` bleibt bewusst
  ausserhalb (unsichtbarer Klick-Catcher, soll nicht mitausblenden).
- `Settings.qml` (neues Singleton, minimal) — nur `barOpacity`, noch ohne
  Persistenz (kommt in Etappe 9).

**Live verifiziert** (nicht nur fehlerfreies Laden):
- `matugen image <echtes-Wallpaper>` einmal real ausgeführt (ohne
  `[config.wallpaper]`, das war fuer diesen Test kurz auskommentiert, um
  nicht ungefragt den Desktop-Hintergrund des Nutzers zu aendern) —
  `~/.cache/blobs-bar/colors.json` enthielt danach alle sieben erwarteten
  Keys mit echten Hex-Werten.
- Bar gestartet, Screenshot: der Rahmenton aller drei Blobs war sichtbar
  heller (`#90909a` aus der echten Palette) als der alte hartcodierte
  Fallback (`#44464f`) — Theme.qml zieht also wirklich aus der Datei, nicht
  aus dem Fallback.
- `BarState.active` temporär auf `"left"` gesetzt: Screenshot zeigt Tag-Zahl
  pixelfest oben rechts, Beschriftung "Workspace", Transparenz-Slider bei
  100 % und ein 4-spaltiges Grid mit echten, geladenen Wallpaper-Thumbnails
  (echte Landschaftsfotos, nicht nur Platzhalter-Rechtecke) — Mitte/rechte
  Kugel blieben unberührt in Ruheposition.
- `Settings.barOpacity` temporär auf `0.4` gesetzt: zweiter Screenshot
  zeigt alle drei Blobs sichtbar transparent gegen den Wallpaper-Hintergrund
  durchscheinend statt blickdicht schwarz.
- Danach beide Werte zurück auf `"none"`/`1.0`, `[config.wallpaper]` wieder
  aktiviert (aber seither nicht real ausgelöst — siehe unten), Testprozess
  jedes Mal beendet.

**Nicht verifiziert**: `[config.wallpaper]`s `awww img {{ image }}`-Aufruf
selbst (würde den echten Desktop-Hintergrund des Nutzers ändern — nicht
ungefragt ausgelöst) und der Klick auf ein Wallpaper-Thumbnail in der
laufenden Shell (dieselbe fehlende Input-Simulation wie beim Launcher,
siehe dortige Stolperfalle — hier aber geringeres Risiko, da nur ein
gewöhnlicher `MouseArea`+`Quickshell.execDetached`, ein Muster, das an
mehreren Stellen in diesem Repo bereits erprobt ist, z.B.
`shellwall`/`fullshell/WallpaperTab.qml`).

## Was funktioniert (Etappe 9)

- `Settings.qml` liest/schreibt jetzt `~/.config/blobs-bar/settings.json`
  — exakt dasselbe Muster wie `bars/fisheye/Config.qml` (`FileView`,
  `onLoadFailed` schreibt Defaults beim allerersten Start, `watchChanges`
  liest bei externer Änderung neu ein). Der Transparenz-Slider in
  `WorkspaceContent.qml` ruft `Settings.save()` erst bei `onReleased`, nicht
  bei jeder Zwischenposition während des Drags — die Live-Anzeige bleibt
  trotzdem sofort reaktiv, weil `Bar.qml`s `opacity`-Bindung direkt an
  `Settings.barOpacity` hängt, unabhängig davon, wann gespeichert wird.
- Polish-Durchgang: schnelles Hin-und-Herklicken zwischen allen fünf
  `BarState`-Werten durchgespielt (siehe "Live verifiziert" unten) — läuft
  glatt, weil jede Morph-Eigenschaft (`width`/`height`/`radius` in
  `MorphBlob`) eine reine `Behavior`-gebundene Werteänderung ist. Qt
  interpoliert bei einer erneuten Zieländerung automatisch vom aktuellen
  (nicht vom alten Ziel-)Wert weiter — das ist ein Standard-Garantie von
  QtQuick `Behavior`, nicht etwas, das in diesem Projekt selbst
  nachgebaut wurde, deshalb "by construction" statt durch eine
  Frame-für-Frame-Prüfung verifiziert.

**Live verifiziert** (nicht nur fehlerfreies Laden):
- Bestehende `settings.json` gelöscht, Shell gestartet → Datei wurde mit
  `{"barOpacity": 1}` neu angelegt (Default-Schreibpfad funktioniert). Dabei
  eine Laufzeit-Warnung beobachtet ("got operation finished from dropped
  operation") — probeweise dieselbe Situation bei `fisheye` ausgelöst
  (dessen `config.json` kurz entfernt, Shell gestartet, Datei danach wieder
  hergestellt): identische Warnung, also eine bekannte, harmlose
  Quickshell-Eigenheit dieses genauen Musters, kein von mir eingeführter
  Bug.
- `settings.json` manuell auf `{"barOpacity": 0.55}` gesetzt, Shell
  gestartet, Screenshot — Bar startete sichtbar bei ~55% Deckkraft statt
  100%, bestätigt den Lesepfad. Der Schreibpfad ist durch den
  Default-Schreibtest oben bereits erledigt (`save()` ist derselbe
  Code-Pfad).
- Temporärer Stresstest in `shell.qml` (danach vollständig wieder entfernt):
  ein 60ms-Timer hat `BarState.active` 8 Sekunden lang durch alle fünf Werte
  gejagt (schneller als jede Morph-Dauer, inklusive wiederholtem
  Auf/Ab-Toggeln von `WlrKeyboardFocus.Exclusive` durch die
  Launcher-Übergänge) — **keine einzige Warnung/Fehlermeldung**, sauberer
  Exit. Zwei Zwischenstand-Screenshots während des Laufs zeigen einen
  glatten, nicht-verglitchten Übergangszustand (teilweise gewachsene Pille
  mit halb eingeblendetem Suchfeld-Crossfade), kein visueller Sprung.
- `settings.json` und `Settings.qml`s Default abschließend auf `1.0`
  zurückgesetzt.

## Nachtrag: Bugfixes nach Nutzer-Feedback (2026-09-13)

Vier vom Nutzer live gemeldete Probleme, alle behoben:

- **Launcher öffnete nicht mit `SUPER,space`**: Ursache war nicht `blobs`
  selbst, sondern Mango-Config-Routing. `blobs` hatte nie einen Eintrag in
  `quickdots/menu/adapters/` (dem Bar-Switcher-System, das den
  `# >>> quickdots >>>`-Block in `~/.config/mango/config.conf` je nach
  aktiver Bar automatisch schreibt, siehe `quickdots/menu/scripts/
  switch-bar.sh`). Ohne `hasLauncher: true` im Adapter fiel `SUPER,space`
  auf `quickdots/menu`s generischen App-Sucher zurück (`SearchState.qml`)
  statt `blobs`' eigenen Launcher zu triggern — `blobs`' eigene
  `IpcHandler`/`LauncherState`-Kette (Etappe 4) war die ganze Zeit korrekt,
  wurde nur nie aufgerufen. Fix: `quickdots/menu/adapters/blobs.json`
  angelegt (`hasLauncher: true`, `keybinds` mit der echten
  `ipc call launcher toggle`-Zeile, Theme-Werte aus `Theme.qml`s
  Fallback-Palette übernommen), danach `switch-bar.sh blobs` einmal
  laufen lassen — schreibt den Bind jetzt korrekt (per `grep` in
  `config.conf` bestätigt) und reloaded Mango automatisch
  (`mmsg dispatch reload_config`, Teil des Skripts).
- **Wallpaper-Grid nicht scrollbar**: `WorkspaceContent.qml`s `Grid` (4
  Spalten, bei den echten 41 Bildern 11 Zeilen à 60px) stand direkt in der
  festen ~230px-Panelhöhe ohne `Flickable` — der Überschuss wurde vom
  `clip: true` der `MorphBlob`-Fläche (Etappe 3) unsichtbar abgeschnitten,
  nicht nur unschön, sondern komplett unerreichbar. Fix: Grid steckt jetzt
  in einem `Flickable` (`contentHeight: wallpaperGrid.height`,
  `boundsBehavior: StopAtBounds`) + einem minimalen selbstgebauten
  Scrollbar-Indikator (`visibleArea.yPosition/heightRatio`, kein
  `QtQuick.Controls.ScrollBar` — Konvention dieses Repos, siehe
  "Konventionen").
- **Escape schloss nur den Launcher**: `Bar.qml`s
  `WlrLayershell.keyboardFocus` war fest an `middleBlob.mode ===
  "launcher"` gebunden — Kalender/Workspace/Audio/System hielten nie
  Tastaturfokus, ein Escape-Druck kam dort also nie an (Design-Entscheidung
  aus Etappe 8, siehe "Stolperfallen"). Nutzerwunsch war aber Escape für
  alle vier Panels. Fix: Bedingung auf `BarState.active !== "none"`
  erweitert (deckt alle fünf `BarState`-Werte ab, nicht nur `"launcher"`);
  `blobsLayer` (das Item mit den drei Blobs) bekommt jetzt
  `Keys.onEscapePressed: BarState.close()` + `forceActiveFocus()` bei jedem
  `BarState.onActiveChanged` außer `"launcher"` (der Launcher fokussiert
  weiterhin sein eigenes Suchfeld, dessen `Keys.onEscapePressed` schon seit
  Etappe 4 existiert).
- **Keine Gap oben, Bar überlappte Fenster**: `exclusiveZone: 0` (Etappe 1,
  Auftrag Abschnitt 2: "schwebt über den Fenstern, reserviert keinen
  Platz") war eine bewusste Auftrags-Entscheidung, die der Nutzer jetzt
  explizit umgekehrt haben wollte — echte reservierte Fläche oben, wie eine
  normale Bar. Fix: `exclusiveZone: Theme.topMargin + Theme.barHeight`
  (nur die Ruhehöhe, nicht `Theme.maxPanelHeight` — sonst wäre dauerhaft so
  viel Platz reserviert wie das größte offene Panel braucht). Ein offenes
  Panel wächst weiterhin ungehindert über diese Zone hinaus nach unten
  (schwebt dann wie gehabt über Fenstern), nur der Ruhezustand reserviert
  jetzt echten Platz. **Dies ist eine bewusste Abweichung vom
  Ursprungs-Prompt Abschnitt 2** (siehe "Abweichungen" oben für den
  bisherigen Abweichungs-Stil) — auf expliziten Nutzerwunsch, nicht durch
  einen Fehler im Auftrag.

**Live verifiziert** (nicht nur fehlerfreies Laden): `qs -p .` neu
gestartet nach jeder Änderung, `INFO: Configuration Loaded` ohne
`ERROR` jedes Mal (Log in `/tmp/blobs-*.log` geprüft). Per Screenshot:
Ruhezustand zeigt jetzt eine echte Lücke zwischen Bar und dem
darunterliegenden Fenster (vorher lag das Fenster direkt unter der Bar).
Launcher per `qs -p . ipc call launcher toggle` (derselbe Aufruf, den der
gefixte Mango-Bind jetzt auslöst) geöffnet und wieder geschlossen —
Suchfeld mit Platzhalter "Tippen zum Suchen..." erschien korrekt. Linke
Kugel testweise über `BarState.qml`s Default kurz auf `"left"` gesetzt,
neu gestartet, Screenshot — Wallpaper-Grid zeigte nur noch eine Zeile
sichtbar plus einen sichtbaren Scrollbar-Indikator rechts (vorher wären
alle 11 Zeilen bis auf die erste unerreichbar gewesen), Transparenz-Slider
korrekt bei 100 %. Danach `BarState.qml`s Default zurück auf `"none"`,
sauberer Neustart, kein Fehler.
**Nicht live verifiziert** (kein `wtype`/`ydotool`): dass Escape bei
echtem Tastendruck tatsächlich ankommt (Code-Pfad ist aber jetzt derselbe
wie beim Launcher, der über die `Exclusive`-Fokus-Vergabe testbar war).

## Ursprungs-Prompt

Der vollständige Auftrag (deutsch) liegt in
`quickshell-bar-prompt-v2.md` neben dieser README.
