# simple — Bar + App-Launcher für mango

Schlanke Quickshell-Bar für MangoWM: eine 34px-Leiste oben (Tags, Uhr,
MPRIS, Lautstärke, Benachrichtigungen/DND, Power-Menü) plus
ein eigener App-Launcher mit Fuzzy-Suche. Voller Auftrag steht unten unter
"Ursprungs-Prompt".

## Kurzfassung

**Abhängigkeiten:**
- Quickshell ≥ 0.3.0
- mango (liefert `mmsg` für Tag-Status/-Wechsel und Fokus-Infos)
- Pipewire/wireplumber (Lautstärke-Icon)
- ein laufender MPRIS-Player ist optional — das Media-Widget blendet sich
  ohne aus
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
Modules/Bar/Volume.qml                Pipewire
Modules/Bar/Notifications.qml           DND-Umschalter (reiner UI-Zustand)
Modules/Bar/Power.qml                     Power-Icon
Modules/Bar/PowerMenu.qml                     Sperren/Logout/Reboot/Shutdown
Modules/Launcher/Launcher.qml       Overlay-Fenster, zentriert, LazyLoader-geladen
Modules/Launcher/SearchField.qml      Suchfeld
Modules/Launcher/AppList.qml            App-Liste
```

`Colors.qml`/`Settings.qml`/`Apps.qml`/`MangoIpc.qml` liegen bewusst im
Wurzelverzeichnis statt in einem `Config/`- oder `Services/`-Unterordner:
ein `pragma Singleton` löst in dieser Quickshell-Version nur über denselben
Ordner oder eine reine `".."`-Elternkette zuverlässig auf — ein Import quer
in einen Geschwisterordner (`Modules/Bar/` → `Config/`) liefert sonst ein
Objekt mit ausschließlich `undefined`-Properties, ganz ohne
Fehlermeldung. Jedes Modul erreicht die Singletons daher per
`import "../.."`.

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
