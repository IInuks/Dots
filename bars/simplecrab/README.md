# simplecrab — Bar + App-Launcher + Spinnen-Modus für mango

Fork von `bars/simple` (siehe dort für die Historie bis 2026-09-14): eine
34px-Leiste oben (Tags, Uhr, MPRIS, Lautstärke, Benachrichtigungen/DND,
Power-Menü), ein App-Launcher mit Fuzzy-Suche, und neu ein **Spinnen-Modus**
— ein Bar-Trigger öffnet ein Menü mit An/Aus-Schalter, virtuellem Joystick,
Geschwindigkeits-/Größen-Slider und Figurenauswahl (Spinne/Krabbe); ist der
Modus an, läuft die gewählte Figur an der Zeigerposition mit, steuerbar per
WASD/Pfeiltasten oder Joystick, Leertaste klickt, Enter schließt das Fenster
darunter, Escape beendet den Modus. Details, Grenzen und Troubleshooting
unter "Spinnen-Modus" weiter unten. `simple` selbst ist von diesem Fork
unberührt und bleibt die aktiv laufende Bar.

## Kurzfassung

**Abhängigkeiten:**
- Quickshell ≥ 0.3.0
- mango (liefert `mmsg` für Tag-Status/-Wechsel, Fokus-Infos, und -- neu --
  Fensterliste/-position + `killclient` für den Spinnen-Modus)
- Pipewire/wireplumber (Lautstärke-Icon)
- ein laufender MPRIS-Player ist optional — das Media-Widget blendet sich
  ohne aus
- **Neu für den Spinnen-Modus:** `wlrctl` (Paket `wlrctl` in nixpkgs) --
  bewegt/klickt den echten Mauszeiger. **War beim Bauen dieser Erweiterung
  nicht installiert und ist ungetestet** -- siehe Abschnitt "Spinnen-Modus"
  unten, was das konkret bedeutet.
- **Adaptives Theme:** `Colors.qml` liest `~/.cache/wal/colors.json` (pywal)
  und färbt sich live um, sobald sich die Datei ändert — kein Bar-Neustart
  nötig. `shellwall` (`~/quickdots/shellwall`, `Config.qml`: `runPywal`)
  schreibt diese Datei bei jedem Wallpaper-Wechsel neu. Fehlt die Datei
  (z. B. `wal` noch nie gelaufen), fällt `Colors.qml` auf die ursprüngliche
  feste Palette zurück.
- `nerd-fonts.jetbrains-mono` **aktiv installiert** (siehe "Bekannte
  Lücken" unten — in `/etc/nixos/configuration.nix` bereits deklariert,
  aber im aktuell laufenden System nicht aktiv)

**Start (Test/Debug, ohne Bar-Switcher):**
```
qs -p ~/quickdots/bars/simple
```

**Als aktive Bar registrieren** (empfohlener Weg): über das quickdots-Menü
auf "simple" wechseln, oder direkt
```
~/quickdots/menu/scripts/switch-bar.sh simple
```
Das startet die Bar, schreibt den `# >>> quickdots >>>`-Block in
`~/.config/mango/config.conf` neu (u.a. den SUPER+Space-Keybind) und lädt
mango live neu. Die Keybind-/Theme-Angaben dafür liegen in
`quickdots/menu/adapters/simple.json` (`hasLauncher: true`, Keybind
`qs -p ~/quickdots/bars/simple ipc call launcher toggle`).

**Fallback ohne Bar-Switcher:**
```
qs -p ~/quickdots/bars/simple ipc call launcher toggle
```

## Bekannte Lücken

- Mehrfach aktive Tags pro Monitor (mango erlaubt das) werden nur als
  "irgendein aktiver Tag hat diese Nummer" angezeigt — die Bar geht von
  "ein Tag = ein aktueller Workspace" aus, wie im Auftrag beschrieben.

**Behoben (2026-09-14):** Icons rendern nicht mehr als Tofu-Boxen.
`nerd-fonts.jetbrains-mono` war in `/etc/nixos/configuration.nix`
deklariert, aber im laufenden System nicht aktiv. Statt eines vollen
`sudo nixos-rebuild switch` (bewusst nicht ausgeführt) per
`nix profile install nixpkgs#nerd-fonts.jetbrains-mono` +
`fc-cache -f` in den Nutzer-Profil-Font-Pfad installiert — deckt sich
nicht mit dem deklarierten System-Zustand, ein künftiger
`nixos-rebuild switch` macht die Schrift zusätzlich system-weit
verfügbar, ohne dass das hier etwas kaputt macht.

## Struktur

```
shell.qml               Root: Bar pro Bildschirm, Launcher per LazyLoader, IpcHandler
Colors.qml               Singleton: Farben + Font (siehe Kommentar zum Root-Standort)
Settings.qml              Singleton: Größen/Zeiten/Kommandos, keine Magic Numbers in Modulen
MangoIpc.qml               Singleton: mmsg-IPC (Tags, Monitore, Fokus)
Apps.qml                    Singleton: Fuzzy-Suche + Nutzungshäufigkeit (Launcher)
Modules/Bar/Bar.qml           PanelWindow, 34px, oben
Modules/Bar/Workspaces.qml      Tags 1..6 + aktiver Fenstertitel
Modules/Bar/Clock.qml             Datum + Uhrzeit
Modules/Bar/Media.qml               MPRIS
Modules/Bar/Volume.qml                Pipewire, Klick oeffnet VolumeMenu
Modules/Bar/VolumeMenu.qml               Regler + Stummschalter (Popup)
Modules/Bar/Notifications.qml           DND-Umschalter (reiner UI-Zustand)
Modules/Bar/Power.qml                     Power-Icon
Modules/Bar/PowerMenu.qml                     Sperren/Logout/Reboot/Shutdown
Modules/Launcher/Launcher.qml       Overlay-Fenster, zentriert, LazyLoader-geladen
Modules/Launcher/SearchField.qml      Suchfeld
Modules/Launcher/AppList.qml            App-Liste

SpiderState.qml                Singleton: persistierte Spinnen-Einstellungen (FileView+JsonAdapter)
SpiderController.qml             Singleton: Position/Tastenzustand/60fps-Tick/Physik
Input.qml                          Singleton: EINZIGE Stelle mit Eingabe-Simulation (wlrctl/mmsg)
FigureRegistry.qml                   Singleton: Liste der waehlbaren Figuren (Menue-Datenquelle)
Modules/Spider/SpiderTrigger.qml       Bar-Icon, oeffnet/schliesst das Menue
Modules/Spider/SpiderMenu.qml            Popup-Menue (Schalter/Joystick/Slider/Figurenwahl)
Modules/Spider/SpiderToggle.qml            An/Aus-Schalter-Widget
Modules/Spider/SpiderSlider.qml              Beschrifteter Slider
Modules/Spider/SpiderJoystick.qml              Ziehbarer Analog-Joystick
Modules/Spider/SpiderOverlay.qml                 Klick-durchlaessiges Overlay + Tastatursteuerung
Modules/Spider/Figures/FigureView.qml              Laedt die per figureId gewaehlte Figur
Modules/Spider/Figures/Spider/Spider.qml             Figur: Spinne
Modules/Spider/Figures/Crab/Crab.qml                 Figur: Krabbe
```

`Colors.qml`/`Settings.qml`/`Apps.qml`/`MangoIpc.qml` liegen bewusst im
Wurzelverzeichnis statt in einem `Config/`- oder `Services/`-Unterordner:
ein `pragma Singleton` löst in dieser Quickshell-Version nur über denselben
Ordner oder eine reine `".."`-Elternkette zuverlässig auf — ein Import quer
in einen Geschwisterordner (`Modules/Bar/` → `Config/`) liefert sonst ein
Objekt mit ausschließlich `undefined`-Properties, ganz ohne
Fehlermeldung. Jedes Modul erreicht die Singletons daher per
`import "../.."`.

## Spinnen-Modus

### Benutzung

- Spinnen-Icon (🕷) ganz rechts in der Bar öffnet/schließt das Menü.
- Schalter oben im Menü an/aus. Joystick darunter steuert per Ziehen
  (Richtung + Auslenkung = Bewegungsrichtung + -geschwindigkeit, Loslassen
  = Mitte). Zwei Slider (Geschwindigkeit, Größe), darunter die
  Figurenauswahl.
- **Solange der Modus an ist** (auch bei geschlossenem Menü):
  `W/A/S/D` oder Pfeiltasten bewegen die Figur (Diagonalen normalisiert,
  nicht schneller), `Leertaste` = Linksklick an der aktuellen Position,
  `Enter` = Fenster unter der Figur schließen, `Escape` = Modus aus.
- Einstellungen (an/aus, Geschwindigkeit, Figur, Größe) liegen unter
  `~/.local/state/quickshell/by-shell/<hash>/spider.json` und überleben
  einen Neustart der Shell.

### Wichtig: "enabled" wird buchstäblich mitgespeichert

Wie im Auftrag gewünscht ("alle Einstellungen persistiert") ist auch der
An/Aus-Zustand Teil von `spider.json`. Das heißt konkret: startet die Shell
neu, während der Modus an war (Absturz, `nixos-rebuild`, manuelles
Neustarten), kommt der Modus **sofort wieder an** — inklusive sofortigem
exklusivem Tastatur-Grab (siehe nächster Abschnitt). Überrascht das: einmal
Escape drücken.

### Der kritische Punkt: Tastaturfokus nur wenn wirklich aktiv

Das Overlay-Fenster (`Modules/Spider/SpiderOverlay.qml`) existiert nur,
solange `SpiderState.enabled` true ist — ein `LazyLoader` in `shell.qml`
erzeugt es bei jedem Einschalten komplett neu und zerstört es beim
Ausschalten komplett, statt eine dauerhafte Surface umzuschalten. Grund:
mango vergibt einer Layer-Surface Keyboard-Fokus (gegen mangos eigenen
Quellcode geprüft) nur bei ihrem allerersten Commit oder — nur wenn sie
schon OnDemand ist — bei einem Klick, der vor dem fokusändernden Commit
ankommt. Ein bloßes Umschalten von `keyboardFocus` auf einem langlebigen
Fenster hätte den Fokus also nicht zuverlässig gewonnen, weder per
Menü-Klick noch (schon gar nicht) wenn der Modus später mal per Hotkey
statt per Klick eingeschaltet wird. Die Kehrseite ist genau der gewünschte
Effekt: **ist der Modus aus, existiert das Fenster nicht — die Shell kann
in dem Zustand unter keinen Umständen Tastaturfokus greifen**, normales
Tippen ist strukturell unbeeinflusst, nicht nur zufällig.

Selbst getestet (per `qs -p . -n`, kurz laufen lassen): Bar lädt fehlerfrei,
Overlay + Figur + Controller-Loop laufen ohne QML-Fehler/-Warnungen, auch
mit `enabled: true` erzwungen. **Nicht** getestet werden konnte damit die
eigentliche Wayland-Fokusvergabe von mango live unter echter Tastatureingabe
(das hätte für die Dauer des Tests wirklich jede Taste system-weit
abgefangen) — probier das im Alltag zuerst kurz aus (Menü an, kurz WASD,
Escape), bevor du dich darauf verlässt.

**Wenn Tasten nicht ankommen:**
1. Prüfen, ob das Overlay überhaupt existiert: `SpiderState.enabled` muss
   true sein (Schalter im Menü, oder `cat
   ~/.local/state/quickshell/by-shell/<hash>/spider.json`).
2. `qs -p . -n` im Terminal laufen lassen und nach Fehlern/Warnungen bei
   `SpiderOverlay` in der Konsole schauen.
3. Escape geht in jedem Fall, solange das Overlay lebt (eigener
   `Keys.onPressed`-Zweig, unabhängig von WASD) — hängt selbst das, ist der
   Fokus komplett woanders gelandet; Modus dann über den Schalter im Menü
   ausschalten (der schreibt `SpiderState.enabled` direkt, ohne auf das
   Overlay angewiesen zu sein).

### Bewegung, Zeiger, Fenster schließen — bewusste Abweichungen vom Auftrag

Der Auftrag beschrieb ydotool (`mousemove -a`, `click 0xC0`) + wlrctl/
simulierten Keybind als Fallback zum Schließen. Nach Prüfung des Systems
(siehe unten) stattdessen:

- **Pointer-Bewegung/Klick: `wlrctl`, nicht ydotool.** ydotool/ydotoold war
  auf diesem System nicht installiert (kein Systemdienst, kein
  `/dev/uinput`-Setup). mango bindet dagegen nativ `wlr_virtual_pointer_v1`
  ein (gegen `mango.c` geprüft) — `wlrctl` spricht genau dieses Protokoll
  als reiner Wayland-Client, ganz ohne Root/uinput/Systemdienst.
  **Unverifiziert:** `wlrctl` war beim Bauen nicht installiert, die
  CLI-Syntax in `Input.qml` (`wlrctl pointer move <dx> <dy>`, `wlrctl
  pointer click left`) ist nach allgemeiner Konvention geraten. Nach
  Installation mit `wlrctl --help` gegenprüfen — weicht sie ab, nur die
  zwei `Quickshell.execDetached(...)`-Zeilen in `Input.qml` anpassen.
- **Bewegung ist relativ, nicht absolut.** `SpiderController.qml` führt die
  Position ohnehin selbst als alleinige Wahrheit (die Shell liest den
  echten Zeiger nie zurück) und kennt bei jedem Tick das exakte Delta seit
  dem letzten Sync — relative Bewegung macht die unsichere Frage nach
  Absolut-Koordinatensystem/Output-Normalisierung komplett irrelevant.
  Fasst du während des Modus die echte Maus selbst an, laufen beide
  Positionen auseinander, bis der Modus aus- und wieder eingeschaltet wird
  (Neuzentrierung).
- **Sync-Rate des echten Zeigers folgt seit 2026-09-15 jedem Tick** (voller
  ~60fps-Takt, `Settings.spiderPointerSyncEveryNTicks: 1`) — Nutzer-Wunsch,
  der echte Zeiger soll sichtbar immer exakt auf der Figur stehen, kein
  Nachlaufen in Schüben mehr. Kostet 60 `wlrctl`-Spawns/Sekunde während
  Bewegung statt vorher ~20 (kurzlebiger Prozess pro Aufruf); auf diesem
  System bisher unauffällig. Vor jedem Klick (Leertaste) wird der
  ausstehende Rest ohnehin sofort nachgeholt, damit an der richtigen Stelle
  geklickt wird.
- **Startposition wird seit 2026-09-15 von der echten Zeigerposition
  übernommen**, nicht mehr von der Bildschirmmitte. `SpiderController.start()`
  fragt einmalig `mmsg get cursorpos` ab und springt auf das Ergebnis (siehe
  `_onCursorQueried`); vorher blieb die Figur dauerhaft um genau den Versatz
  "Bildschirmmitte ↔ tatsächliche Mausposition beim Einschalten" verschoben,
  weil rein relative Bewegung (siehe oben) diesen Versatz nie von selbst
  ausgleicht.
- **Fenster schließen: `mmsg dispatch killclient client,<id>`, kein
  wlrctl-Toplevel-Close, kein simulierter Keybind-Fallback.** Das ist
  tatsächlich gegen mangos Quellcode verifiziert
  (`src/dispatch/bind_define.h`) und gegen die echte `mmsg --help`-Ausgabe
  auf diesem System — kein Raten nötig, und robuster als
  Pointer-hinbewegen-warten-klicken (kein Timing-Rennen mit
  `focus_follows_mouse`/`warpcursor` in `config.conf`). Welches Fenster
  unter der Figur liegt, wird per `mmsg get all-clients` (liefert x/y/
  Breite/Höhe pro Fenster) per Rechtecktest bestimmt — Bar/Menü/Overlay
  sind Layer-Surfaces und tauchen dort gar nicht auf, "nur Desktop/eigene
  Bar darunter" ergibt sich also von selbst.
  **Unverifiziert:** `all-clients` liefert keine explizite
  Stapelreihenfolge; bei überlappenden Fenstern wird der fokussierte
  Treffer bevorzugt, sonst der erste der Liste (`Input.qml::
  _onClientsQueried`). Wählt es beim Überlappen zuverlässig das falsche
  Fenster, bitte melden — das ist der einzige noch unsichere Teil dieser
  Kette.
- **`keyCombo()` aus dem Auftrag wurde nicht gebaut.** Es war als
  Fallback für das Schließen gedacht; da `killclient` das robust und ohne
  Fallback löst, gäbe es aktuell nichts, das eine generische
  Tastenkombinations-Simulation aufruft — toter Code. `Input.qml` bleibt
  bewusst bei den zwei tatsächlich genutzten Funktionen (`moveRelative`,
  `click`, `closeAt`); eine `keyCombo()`-Funktion lässt sich bei Bedarf
  jederzeit ergänzen, ohne an den Aufrufstellen etwas zu ändern.

### Nur ein Bildschirm

Bewegung/Klemmung ist auf den Bildschirm begrenzt, auf dem der Modus
eingeschaltet wurde (`SpiderController.start()` nimmt dessen Breite/Höhe).
Kein Wechsel auf einen Nachbarmonitor bei Bewegung über den Rand hinaus —
auf diesem System ohnehin nur ein Monitor (`DP-4`, siehe `mmsg
get all-monitors`).

### Neue Figur hinzufügen

Ehrlich gesagt drei Schritte, nicht einer — wegen derselben
Import-Eigenheit, die schon `Colors.qml`/`Settings.qml` zu Root-Singletons
macht (siehe deren Kommentare): Figuren-Komponenten sind aber gewöhnliche
(nicht-Singleton) QML-Typen, für die diese Einschränkung nicht gilt, daher
reicht ein normaler Ordner-Import.

1. `Modules/Spider/Figures/<Name>/<Name>.qml` anlegen — ein `Item` mit den
   Properties `size`, `heading` (radians), `moving` (bool), siehe
   `Figures/Spider/Spider.qml` als Vorlage.
2. In `Modules/Spider/Figures/FigureView.qml`: `import "<Name>"` ergänzen
   plus einen Eintrag in `_componentMap`.
3. In `FigureRegistry.qml`: `{ id: "<name>", name: "<Anzeigename>" }` zur
   Liste hinzufügen — die Menü-Auswahl baut sich automatisch daraus auf.

## Abweichungen vom Ursprungs-Prompt

Der ursprüngliche Auftrag war für **Hyprland** und `~/.config/quickshell/`
formuliert; der Nutzer hat danach korrigiert: Ziel ist `mango` und
`quickdots/bars/simple`. Alles unten bezieht sich auf die korrigierte
Fassung.

- **Workspaces = mango-Tags, nicht Hyprland-Workspaces.** Es gibt kein
  `Quickshell.Hyprland`-Modul unter mango. Tag-Status/-Wechsel läuft über
  `MangoIpc.qml` (adaptiert aus `bars/fisheye/MangoIpc.qml`, gleiche
  `mmsg`-Kommandos: `mmsg watch all-monitors`, `mmsg dispatch
  viewcrossmon,<index>,<monitor>`).
- **Kein GlobalShortcut/FocusGrab.** Mango kennt weder Hyprlands
  `hyprland_global_shortcuts_v1` noch dessen Input-Grab-Protokoll.
  SUPER+Space läuft deshalb komplett außerhalb des Quickshell-Prozesses
  über mangos eigenen Keybind (`bind=SUPER,space,spawn,qs -p .../simple ipc
  call launcher toggle`, verdrahtet über `quickdots/menu/adapters/
  simple.json` + `switch-bar.sh`), nicht über ein in-process `GlobalShortcut`.
- **"Klick außerhalb schließt" ohne Focus-Grab.** Launcher- und
  Power-Menü-Fenster spannen den ganzen Bildschirm transparent auf; ein
  Klick auf den transparenten Rand schließt, ein Klick auf das sichtbare
  Panel selbst wird von einer eigenen MouseArea abgefangen. Erreicht
  denselben Effekt wie Hyprlands `HyprlandFocusGrab`, rein über
  Surface-Größe + MouseArea-Reihenfolge.
- **`WlrKeyboardFocus.OnDemand` statt `Exclusive`** für den Launcher: mango
  gewährt einer On-Demand-Layer-Surface Keyboard-Fokus nur bei deren
  allererstem Commit, nicht bei einer wiederverwendeten Surface — deshalb
  auch die frische Surface pro Öffnen via `LazyLoader`.
- **`onAccent` → `accentInk`.** `onAccent` wird von QML als
  Signal-Handler-Deklaration geparst (`/^on[A-Z]/`) und scheitert beim
  Laden mit "Cannot assign a value to a signal" — umbenannt, gleiche Farbe
  (`#1c1b1a`).
- **Icons als `"\uXXXX"`-Escapes statt eingebetteter Unicode-Zeichen** im
  QML-Quelltext: rohe Private-Use-Area-Zeichen sind beim Schreiben der
  Dateien mehrfach kommentarlos als leerer String angekommen (nicht
  reproduzierbar, vermutlich ein Encoding-Stolperstein beim Erzeugen der
  Dateien) — die Escape-Schreibweise ist reines ASCII und dadurch robust.
- **Power-Menü-Kommandos an dieses System angepasst**: `swaylock` (einzig
  installierter Lock-Screen) statt `hyprlock`, `mmsg dispatch quit` statt
  `hyprctl dispatch exit`.
- **Nachträglich (Nutzer-Wunsch, 2026-09-14):** Uhr auf 24h umgestellt
  (`Settings.clockFormat`: `HH:mm` statt `hh:mm AP`); belegte (aber nicht
  aktive) Tags bekommen jetzt ebenfalls eine Unterstreichung, in
  `Colors.accent` statt `Colors.accentAlt` (aktiver Tag), zur
  Unterscheidung; `Colors.qml` von festen Hex-Werten auf ein
  pywal-adaptives Theme umgebaut (siehe "Abhängigkeiten" oben), inklusive
  400ms Farb-Crossfade bei Palettenwechsel statt hartem Sprung; die
  benachbarten Unterstreichungen verschmelzen jetzt zu einer durchgehenden
  Linie statt einzelner Striche mit Lücke dazwischen.
- **Nachträglich (Nutzer-Wunsch, 2026-09-14):** Update-Button entfernt
  (kein Icon links neben der Lautstärke mehr) — `Modules/Bar/UpdateButton.qml`
  und die dazugehörigen `Settings.updateCommand`/`Settings.terminalCommand`
  gelöscht, da danach ungenutzt.
- **Nachträglich (Nutzer-Wunsch, 2026-09-15):** Menü schließt jetzt auch
  per Escape (`SpiderMenu.qml`: `WlrKeyboardFocus.None` → `OnDemand` plus
  ein Escape-Handler, gleiches Muster wie `SearchField.qml`) — vorher
  blockte `None` laut Projektnotizen jede Tastatureingabe an dem Fenster,
  komplett unabhängig von Escape.
- **Nachträglich (Nutzer-Wunsch, 2026-09-15):** `wlrctl` installiert und
  gegen die echte `--help`-Ausgabe geprüft — die zuvor geratene Syntax in
  `Input.qml` (`pointer move <dx> <dy>`, `pointer click left`) stimmt exakt,
  keine Anpassung nötig. Damit funktioniert Leertaste-Klick jetzt tatsächlich
  (vorher lief der `wlrctl`-Aufruf ins Leere, da das Programm fehlte).
- **Nachträglich (Nutzer-Wunsch, 2026-09-15):** Lautstärke-Icon öffnet per
  Klick jetzt `Modules/Bar/VolumeMenu.qml` (Regler + Stummschalter,
  gleiches Popup-Muster wie `PowerMenu.qml`/`SpiderMenu.qml`, Regler/
  Schalter per Cross-Directory-Import aus `Modules/Spider`
  wiederverwendet) statt direkt beim Klick stummzuschalten. Scrollen auf
  dem Icon ändert die Lautstärke weiterhin sofort, ohne das Menü zu
  öffnen. Dabei nebenbei zwei vorher unentdeckte Bugs behoben:
  - `SpiderController.qml` nutzt `Process`/`StdioCollector` (für den
    Zeigerpositions-Abgleich beim Einschalten, siehe Eintrag weiter unten)
    ohne `import Quickshell.Io` — die Shell scheiterte dadurch komplett am
    Start ("Type Process is not a type"), nicht nur das Lautstärke-Modul.
  - Das eigentliche "es öffnet sich nichts"-Problem war gar kein
    Klick-/Popup-Bug: `Volume.qml`s drei Icon-Glyphen waren beim
    Beschreiben der Datei als leere Strings gelandet (exakt der schon
    weiter unten dokumentierte PUA-Zeichen-Stolperstein) -- das Icon hatte
    dadurch Breite 0, war unsichtbar und bot keine klickbare Fläche.
    Deshalb an dieser einen Stelle testweise via `wlrctl pointer
    move/click` + temporaerem `console.log` in den drei rechten
    Bar-Widgets (Media/Volume/Notifications) nachgewiesen, dass Media und
    Notifications zuverlaessig Klicks bekamen, Volume aber gar keine
    Flaeche hatte -- danach auf `\uXXXX`-Escapes umgestellt (U+F026/
    U+F027/U+F028, gleiche Schreibweise wie ueberall sonst im Projekt).
- **Nachträglich (Nutzer-Wunsch, 2026-09-15):** Spinnen-Modus ergänzt
  (Bar-Trigger, Menü mit Joystick/Slidern/Figurenwahl, Klick-durchlässiges
  Overlay mit WASD-Steuerung, Spinne + Krabbe als erste Figuren). Eigener
  Fork (`simplecrab`) statt Änderung an der laufenden `simple`-Bar. Details
  siehe Abschnitt "Spinnen-Modus" oben — dort auch alle bewussten
  Abweichungen vom ursprünglichen ydotool-basierten Auftrag (`wlrctl` +
  `mmsg dispatch killclient` statt ydotool + simuliertem Schließen-Keybind).

## NixOS-Ergänzungen

Nur für den Spinnen-Modus zusätzlich nötig — der Rest der Bar braucht
nichts über das hinaus, was `bars/simple` schon voraussetzt.

```nix
environment.systemPackages = [
  pkgs.wlrctl
];
```

Das ist alles. Kein Systemdienst, keine `/dev/uinput`-Gruppe, kein
Home-Manager-Modul nötig — `wlrctl` ist ein gewöhnlicher Wayland-Client im
Nutzer-Prozess (nutzt `wlr_virtual_pointer_v1`, das mango schon nativ
anbietet), kein uinput-basiertes Tool wie ydotool. Falls du grundsätzlich
lieber über Home-Manager statt `environment.systemPackages` installierst:
`home.packages = [ pkgs.wlrctl ];` in deiner Home-Manager-Konfiguration tut
dasselbe, beides ist für ein reines CLI-Tool ohne Dienst gleichwertig.

Nach dem Rebuild: `wlrctl --help` prüfen und mit der Syntax in `Input.qml`
abgleichen (siehe Abschnitt "Spinnen-Modus" oben, warum das nötig sein
könnte).

**Falls `wlrctl` sich als unzuverlässig erweist** und du doch auf ydotool
wechseln willst: zusätzlich `services.ydotool.enable = true;` (startet
`ydotoold`) und dafür sorgen, dass dein Nutzer in der Gruppe landet, die
Zugriff auf `/dev/uinput` bekommt (bei NixOS' `ydotool`-Modul i.d.R.
automatisch über eine eigene `uinput`-Gruppe, je nach Modulversion —
`nixos-option services.ydotool` bzw. die Modul-Doku zum genauen
Gruppennamen auf deinem Kanal prüfen). Der Wechsel bleibt lokal auf
`Input.qml` beschränkt, kein anderer Teil der Bar müsste sich ändern.

## Ursprungs-Prompt

Bar + Launcher, Colors.qml + Settings.qml als Singletons, kein Hardcoding
von Farben/Größen/Schrift in den Modulen. Bar oben, 34px, opak,
exclusiveZone aktiv. Links: Tags 1–6 (aktiv = hell + Underline in
accentAlt, belegt = hell ohne Underline, leer = dim), klickbar, Scroll
wechselt vor/zurück; danach Titel des aktiven Fensters (Fallback
"Desktop", max. 60 Zeichen). Mitte: Datum + Uhrzeit ("14 Sep  11:55 AM",
sekündlich). Rechts: MPRIS (Icon + Titel, max. 28 Zeichen, ausgeblendet
ohne Player, Klick = Play/Pause, Scroll = next/prev), Update-Icon
(konfigurierbares Terminal-Kommando), Lautstärke (Pipewire, 5%-Schritte,
Klick mutet), Benachrichtigungs-Icon (Klick togglet DND), Power-Icon
(Menü: Sperren/Logout/Reboot/Shutdown).

Launcher: eigenes Fenster, zentriert, 460×520, exklusiver Keyboard-Grab,
border-radius 8, Panel-Hintergrund. Suchfeld mit Lupen-Icon, darunter
Trennlinie, darunter App-Liste (nur Namen, Zeilenhöhe ~57px, linker
Abstand 20px, Selektion als pinkes Rechteck). Apps aus DesktopEntries,
NoDisplay/Hidden gefiltert, Fuzzy-Suche über Name/genericName/keywords,
score-sortiert; leere Eingabe = zuletzt/häufig genutzt zuerst, sonst
alphabetisch, Nutzungshäufigkeit persistiert unter
`~/.local/state/quickshell/launcher.json`. Tastatur: Up/Down und
Ctrl+J/Ctrl+K navigieren, Enter startet (detached, mit Shell-Umgebung),
Escape schließt, Klick außerhalb schließt. Sanfte Ein-/Ausblendung
(Opacity + Scale, ~120ms).

(Ursprünglich für Hyprland mit `GlobalShortcut`/`IpcHandler` formuliert —
per Nutzer-Korrektur auf mango + `quickdots/bars/simple` umgestellt, siehe
"Abweichungen" oben.)
